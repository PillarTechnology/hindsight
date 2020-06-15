defmodule Aggregate.Feed.FlowTest do
  use ExUnit.Case
  use Placebo
  require Temp.Env

  import Definition, only: [identifier: 1]

  alias Aggregate.TestHelpers.FrameEventGenerator

  @instance Aggregate.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_aggregate,
      key: Aggregate.Feed.Flow,
      set: [
        window_limit: 2,
        window_unit: :second
      ]
    }
  ])

  setup do
    on_exit(fn ->
      Brook.Test.clear_view_state(@instance, "extractions")
      Brook.Test.clear_view_state(@instance, "stats")
    end)

    now = ~U[2020-06-09 18:03:06Z]
    now_string = DateTime.to_iso8601(now)
    allow(DateTime.utc_now(), return: now, meck_options: [:passthrough])

    [now_string: now_string]
  end

  test "aggregates message over a configured period and calls to configured reducers", %{
    now_string: now_string
  } do
    dataset_id = "ds1"
    subset_id = "sb1"

    aggregate =
      Aggregate.new!(
        version: 1,
        dataset_id: dataset_id,
        subset_id: subset_id,
        source:
          Kafka.Topic.new!(endpoints: [localhost: 9092], name: "vaMicroEvents", partitions: 1),
        destination:
          Kafka.Topic.new!(
            name: "consumer-person-aggregate",
            endpoints: [localhost: 9092],
            partitions: 1
          ),
        decoder: Decoder.JsonLines.new!([]),
        dictionary: [
          Dictionary.Type.String.new!(name: "EventID"),
          Dictionary.Type.String.new!(name: "Timestamp"),
          Dictionary.Type.String.new!(name: "Context"),
          Dictionary.Type.Integer.new!(name: "Sequence"),
          Dictionary.Type.String.new!(name: "Module"),
          Dictionary.Type.List.new!(
            name: "BoundingBox",
            item_type: Dictionary.Type.Float.new!(name: "coordinate")
          ),
          Dictionary.Type.Float.new!(name: "Confidence"),
          Dictionary.Type.List.new!(
            name: "Classification",
            item_type: Dictionary.Type.String.new!(name: "objectClassification")
          ),
          Dictionary.Type.String.new!(name: "SampleImage"),
          Dictionary.Type.String.new!(name: "MessageType"),
          Dictionary.Type.String.new!(name: "SampleObject")
        ],
        reducers: [
          Aggregate.Reducer.FrameReducer.new(%{
            sample_image_path: [Access.key(:value), "SampleImage"],
            classification_path: [Access.key(:value), "Classification"]
          })
        ]
      )

    IO.inspect("About to create a supervisor")

    assert {:ok, _pid} =
             start_supervised(
               {Aggregate.Feed.Flow,
                dataset_id: dataset_id,
                subset_id: subset_id,
                from_specs: [{Aggregate.Simple.Producer, aggregate: aggregate}],
                into_specs: [{Aggregate.Test.Consumer, pid: self()}],
                reducers: aggregate.reducers}
             )

    IO.inspect("about to create some events")

    events =
      [246]
      |> Enum.map(&FrameEventGenerator.generate/1)
      |> Enum.map(&to_elsa_message/1)

    events
    |> IO.inspect(label: "sending events")
    |> Aggregate.Simple.Producer.inject_events()

    assert_receive(
      {:event, %{timestamp: now_string, people_count: 1.0}},
      3_000
    )

    more_events =
      [247]
      |> Enum.map(&FrameEventGenerator.generate/1)
      |> Enum.map(&to_elsa_message/1)

    Aggregate.Simple.Producer.inject_events(more_events)

    assert_receive(
      {:event, %{timestamp: now_string, people_count: 1.0}},
      3_000
    )
  end

  defp to_elsa_message(value) do
    %Elsa.Message{
      value: value
    }
  end
end
