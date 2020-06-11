defmodule Aggregate.FeedTest do
  use ExUnit.Case
  # use Placebo

  # setup do
  #   aggregate =
  #     Aggregate.new!(
  #       id: "aggregate-1",
  #       dataset_id: "ds1",
  #       subset_id: "sb1",
  #       source: Source.Fake.new!(),
  #       decoder: Decoder.Noop.new(),
  #       destination:
  #         Kafka.Topic.new!(
  #           endpoints: [localhost: 9092],
  #           name: "topic-1"
  #         ),
  #       reducers: [
  #         Aggregate.Reducer.FrameReducer.new(
  #           classification_path: ["Classification"],
  #           sample_image_path: ["SampleImage"]
  #         )
  #       ]
  #     )

  #   [aggregate: aggregate]
  # end

  # test "Starts up a supervisor with flow children", %{aggregate: aggregate} do
  #   expected_child =
  #     {Aggregate.Feed.Flow,
  #      dataset_id: aggregate.dataset_id,
  #      subset_id: aggregate.subset_id,
  #      from_specs: [{Aggregate.Feed.Producer, aggregate: aggregate}],
  #      into_specs: [
  #        {Aggregate.Feed.Consumer,
  #         dataset_id: aggregate.dataset_id, subset_id: aggregate.subset_id}
  #      ],
  #      reducers: aggregate.reducers}

  #   Aggregate.Feed.init(aggregate: aggregate)

  # end
end
