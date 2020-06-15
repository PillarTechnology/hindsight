defmodule Aggregate.Reducer.FrameReducer do
  defstruct [:sample_image_path, :classification_path, :frame_people_count]

  def new(opts) do
    %__MODULE__{
      sample_image_path: Map.get(opts, :sample_image_path, []),
      classification_path: Map.get(opts, :classification_path, []),
      frame_people_count: %{}
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, %{"frame_people_count" => nil}) do
      %{t | frame_people_count: %{}}
    end

    def init(t, stats) do
      %{t | frame_people_count: Map.get(stats, "frame_people_count", %{})}
    end

    def reduce(t, event) do
      if Enum.any?(get_in(event, t.classification_path), fn x -> x == "person" end) do
        frame = get_in(event, t.sample_image_path)
        new_frames = Map.update(t.frame_people_count, frame, 1, fn v -> v + 1 end)
        %{t | frame_people_count: new_frames}
      else
        t
      end
    end

    def merge(t1, _t2) do
      t1
    end

    def to_event_fields(reducer) do
      []
    end
  end
end
