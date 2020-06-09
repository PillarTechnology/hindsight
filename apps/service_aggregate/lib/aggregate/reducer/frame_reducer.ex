defmodule Aggregate.Reducer.FrameReducer do
  defstruct [:frame_people_count]

  def new(_opts) do
    %__MODULE__{
      frame_people_count: %{}
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, stats) do
      %{t | frame_people_count: Map.get(stats, "frame_people_count")}
    end

    def reduce(t, event) do
      if Enum.any?(event["Classification"], fn x -> x == "person" end) do
        frame = Map.get(event, "SampleImage")
        new_frames = Map.update(t.frame_people_count, frame, 1, fn v -> v + 1 end)
        %{t | frame_people_count: new_frames}
      else
        t
      end
    end

    def merge(_t1, _t2) do
      %{}
    end

    def to_event_fields(_t) do
      []
    end
  end
end
