defmodule AggregateTest do
  use ExUnit.Case
  use Divo
  use Annotated.Retry
  import AssertAsync
  require Temp.Env

  import Events, only: [aggregate_update: 0, aggregate_start: 0]

  @instance Aggregate.Application.instance()

  @moduletag divo: true, integration: true

  Temp.Env.modify([
    %{
      app: :service_aggregate,
      key: Aggregate.Feed.Flow,
      set: [
        window_limit: 10,
        window_unit: :second
      ]
    }
  ])

  @tag timeout: :infinity
  test "will aggregate a video frame dataset" do
    aggregate =
      Aggregate.new!(
        version: 1,
        dataset_id: "vasp-datasetid",
        subset_id: "vasp-subset",
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
            sample_image_path: ["SampleImage"],
            classification_path: ["Classification"]
          })
        ]
      )

    Brook.Test.send(@instance, aggregate_start(), "testing", aggregate)

    wait_for_topic("vaMicroEvents")

    messages = [
      ~s({"MessageType": "1011", "SampleImage": "/ingestion/00AA00AA00AA00AA/frame/246", "Classification": ["person"], "SampleObject": "/ingestion/00AA00AA00AA00AA/frame/246/[0.7008,0.0090,0.7328,0.1168]", "BoundingBox": [0.7008, 0.0090, 0.7328, 0.1168], "Context": "00AA00AA00AA00AA", "Module": "4000", "Confidence": 0.6474, "Sequence": 0, "EventID": "63293442", "Timestamp": "2020-06-08T18:02:56.675309Z"}),
      ~s({"MessageType": "1011", "SampleImage": "/ingestion/00AA00AA00AA00AA/frame/246", "Classification": ["person"], "SampleObject": "/ingestion/00AA00AA00AA00AA/frame/246/[0.7008,0.0090,0.7328,0.1168]", "BoundingBox": [0.7008, 0.0090, 0.7328, 0.1168], "Context": "00AA00AA00AA00AA", "Module": "4000", "Confidence": 0.6474, "Sequence": 0, "EventID": "63293442", "Timestamp": "2020-06-08T18:02:56.675309Z"}),
      ~s({"MessageType": "1011", "SampleImage": "/ingestion/00AA00AA00AA00AA/frame/246", "Classification": ["person"], "SampleObject": "/ingestion/00AA00AA00AA00AA/frame/246/[0.7008,0.0090,0.7328,0.1168]", "BoundingBox": [0.7008, 0.0090, 0.7328, 0.1168], "Context": "00AA00AA00AA00AA", "Module": "4000", "Confidence": 0.6474, "Sequence": 0, "EventID": "63293442", "Timestamp": "2020-06-08T18:02:56.675309Z"})
    ]

    produce("vaMicroEvents", messages)

    Process.sleep(11_000)
    {:ok, _count, messages} = Elsa.fetch([localhost: 9092], "consumer-person-aggregate")
    decoded = Enum.map(messages, fn message -> Jason.decode!(message.value) end)
    assert Enum.any?(decoded, fn message -> message["people_count"] == 3 end)

    # TODO: Maybe have this test that a second set of messages produces a second result
  end

  @retry with: constant_backoff(1_000) |> take(20)
  defp produce(topic, messages) do
    Elsa.produce([localhost: 9092], topic, messages)
  catch
    _, reason ->
      {:error, reason}
  end

  @retry with: constant_backoff(1_000) |> take(20)
  defp wait_for_topic(topic) do
    IO.inspect(topic, label: "waiting for topic")

    case Elsa.topic?([localhost: 9092], topic) do
      true -> {:ok, true}
      false -> {:error, false}
    end
  end

  defp to_iso(date_time), do: NaiveDateTime.to_iso8601(date_time)
end
