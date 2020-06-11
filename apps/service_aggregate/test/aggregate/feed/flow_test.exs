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

    reducers = [
      Aggregate.Reducer.FrameReducer.new(
        sample_image_path: [Access.key(:value), "SampleImage"],
        classification_path: [Access.key(:value), "Classification"]
      )
    ]

    assert {:ok, _pid} =
             start_supervised(
               {Aggregate.Feed.Flow,
                dataset_id: dataset_id,
                subset_id: subset_id,
                from_specs: [Aggregate.Simple.Producer],
                into_specs: [{Aggregate.Test.Consumer, pid: self()}],
                reducers: reducers}
             )

    events =
      [246]
      |> Enum.map(&FrameEventGenerator.generate/1)
      |> Enum.map(&to_elsa_message/1)

    Aggregate.Simple.Producer.inject_events(events)

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

  test "gets it initial state from brook" do
    Brook.Test.with_event(@instance, fn ->
      aggregate =
        Aggregate.Update.new!(
          dataset_id: "ds1",
          subset_id: "sb1",
          stats: %{"min" => 23, "max" => 52}
        )

      identifier(aggregate)
      |> Aggregate.ViewState.Stats.persist(aggregate.stats)
    end)

    assert {:ok, _pid} =
             start_supervised(
               {Aggregate.Feed.Flow,
                dataset_id: "ds1",
                subset_id: "sb1",
                from_specs: [Aggregate.Simple.Producer],
                into_specs: [{Aggregate.Test.Consumer, pid: self()}],
                reducers: [
                  Aggregate.Reducer.MinMax.new(path: [Access.key(:value), "count"])
                ]}
             )

    events = [
      to_elsa_message(%{"name" => "bob", "count" => 5})
    ]

    Aggregate.Simple.Producer.inject_events(events)

    assert_receive {:event, %{"min" => 5, "max" => 52}}, 3_000
  end

  defp to_elsa_message(value) do
    %Elsa.Message{
      value: value
    }
  end
end
