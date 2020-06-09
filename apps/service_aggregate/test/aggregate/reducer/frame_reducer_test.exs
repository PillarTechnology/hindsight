defmodule Aggregate.Reducer.Frame do
  use ExUnit.Case

  alias Aggregate.Reducer.FrameReducer

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
      event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539522",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/246",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/246/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T18:02:56.675309Z"
      }

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
      event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539522",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/246",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/246/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T18:02:56.675309Z"
      }

      second_event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539523",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/247",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/247/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T20:02:56.675309Z"
      }

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
      event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539522",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/246",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/246/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T18:02:56.675309Z"
      }

      second_event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539523",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/246",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/246/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T18:02:56.675309Z"
      }

      output = Aggregate.Reducer.reduce(reducer, event) |> Aggregate.Reducer.reduce(second_event)

      assert output == %FrameReducer{
               sample_image_path: sample_image_path,
               classification_path: classification_path,
               frame_people_count: %{
                 "/ingestion/00AA00AA00AA00AA/frame/246" => 2
               }
             }
    end

    test "not a person event", %{
      sample_image_path: sample_image_path,
      classification_path: classification_path,
      reducer: reducer
    } do
      event = %{
        "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
        "Classification" => ["not a person"],
        "Confidence" => 0.761,
        "Context" => "00AA00AA00AA00AA",
        "EventID" => "42539522",
        "MessageType" => "1011",
        "Module" => "4000",
        "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/246",
        "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/246/[0.5049,0.0129,0.5268,0.1108]",
        "Sequence" => 0,
        "Timestamp" => "2020-06-08T18:02:56.675309Z"
      }

      output = Aggregate.Reducer.reduce(reducer, event)

      assert output == reducer
    end
  end
end
