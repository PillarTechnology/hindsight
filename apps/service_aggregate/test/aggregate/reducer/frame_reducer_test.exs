defmodule Aggregate.Reducer.Frame do
  use ExUnit.Case

  alias Aggregate.Reducer.FrameReducer
  alias Aggregate.TestHelpers.FrameEventGenerator

  setup do
    sample_image_path = ["SampleImage"]
    classification_path = ["Classification"]

    reducer =
      FrameReducer.new(
        sample_image_path: sample_image_path,
        classification_path: classification_path
      )

    %{
      sample_image_path: sample_image_path,
      classification_path: classification_path,
      reducer: reducer
    }
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
      assert output.frame_people_count == Map.get(t, "frame_people_count")
    end
  end

  describe "reduce/2" do
    test "when reducer is empty and a valid event is published, a new frame is added to reducer",
         %{
           sample_image_path: sample_image_path,
           classification_path: classification_path,
           reducer: reducer
         } do
      event = FrameEventGenerator.generate(246)

      output = Aggregate.Reducer.reduce(reducer, event)

      assert output == %FrameReducer{
               sample_image_path: sample_image_path,
               classification_path: classification_path,
               frame_people_count: %{"/ingestion/00AA00AA00AA00AA/frame/246" => 1}
             }
    end

    test "when reducer is not empty and a valid event is published, a new frame is added to reducer",
         %{
           sample_image_path: sample_image_path,
           classification_path: classification_path,
           reducer: reducer
         } do
      event = FrameEventGenerator.generate(246)
      second_event = FrameEventGenerator.generate(247)

      output = Aggregate.Reducer.reduce(reducer, event) |> Aggregate.Reducer.reduce(second_event)

      assert output == %FrameReducer{
               sample_image_path: sample_image_path,
               classification_path: classification_path,
               frame_people_count: %{
                 "/ingestion/00AA00AA00AA00AA/frame/246" => 1,
                 "/ingestion/00AA00AA00AA00AA/frame/247" => 1
               }
             }
    end

    test "multiple events for same frame", %{
      sample_image_path: sample_image_path,
      classification_path: classification_path,
      reducer: reducer
    } do
      event = FrameEventGenerator.generate(246)
      second_event = FrameEventGenerator.generate(246)

      output = Aggregate.Reducer.reduce(reducer, event) |> Aggregate.Reducer.reduce(second_event)

      assert output == %FrameReducer{
               sample_image_path: sample_image_path,
               classification_path: classification_path,
               frame_people_count: %{
                 "/ingestion/00AA00AA00AA00AA/frame/246" => 2
               }
             }
    end

    test "not a person event", %{reducer: reducer} do
      event = FrameEventGenerator.generate(246, %{classification: ["hot dog"]})

      output = Aggregate.Reducer.reduce(reducer, event)

      assert output == reducer
    end
  end
end
