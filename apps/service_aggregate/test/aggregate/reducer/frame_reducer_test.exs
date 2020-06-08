defmodule Aggregate.Reducer.Frame do
  use ExUnit.Case

  alias Aggregate.Reducer.FrameReducer

  setup do
    reducer = FrameReducer.new(%{})

    [reducer: reducer]
  end

  describe "init/2" do
    test "reads state from map", %{reducer: reducer} do
      t = %{
        "frame_people_count" => %{
          "SampleImage1234" => 15,
          "SampleImage5678" => 37
        }
      }

      output = Aggregate.Reducer.init(reducer, t)
      IO.inspect(output)
      assert output.frame_people_count == Map.get(t, "frame_people_count")
    end
  end

  # describe "it does the thing" do
  #   test "reduces a stream of detected objects by frame" do
  #     File.stream!("./test/support/output.txt")
  #     |> Enum.map(fn x -> Jason.decode!(x, keys: :atoms) end)
  #     |> Enum.map(fn map -> Map.take(map, [:Classification, :SampleImage, :Timestamp, :BoundingBox]) end)
  #     |> IO.inspect
  #     # |> Enum.reduce(%{}, fn word, acc ->
  #     #   Map.update(acc, word, 1, & &1 + 1)
  #     # end)
  #     # |> Enum.to_list()    end
  #   end
  # end
end
