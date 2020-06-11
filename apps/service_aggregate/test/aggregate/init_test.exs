defmodule Aggregate.InitTest do
  use ExUnit.Case
  use Placebo

  import Definition, only: [identifier: 1]
  @instance Aggregate.Application.instance()

  setup do
    allow Aggregate.Feed.Supervisor.start_child(any()), return: {:ok, :pid}
    on_exit(fn -> Brook.Test.clear_view_state(@instance, "feeds") end)

    :ok
  end

  test "starts all saved feeds" do
    dictionary = [
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
    ]

    aggregate1 =
      Aggregate.new!(
        id: "aggregate1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictionary: dictionary,
        destination: Destination.Fake.new!(),
        reducers: []
      )

    aggregate2 =
      Aggregate.new!(
        id: "aggregate2",
        dataset_id: "ds2",
        subset_id: "sb2",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictionary: dictionary,
        destination: Destination.Fake.new!(),
        reducers: []
      )

    aggregate3 =
      Aggregate.new!(
        id: "aggregate3",
        dataset_id: "ds3",
        subset_id: "sb3",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictionary: dictionary,
        destination: Destination.Fake.new!(),
        reducers: []
      )

    Brook.Test.with_event(@instance, fn ->
      [aggregate1, aggregate2, aggregate3]
      |> Enum.each(fn aggregate ->
        identifier(aggregate)
        |> Aggregate.ViewState.Aggregations.persist(aggregate)
      end)
    end)

    assert {:ok, :state} = Aggregate.Init.on_start(:state)

    assert_called(Aggregate.Feed.Supervisor.start_child(aggregate1))
    assert_called(Aggregate.Feed.Supervisor.start_child(aggregate2))
    assert_called(Aggregate.Feed.Supervisor.start_child(aggregate3))
  end
end
