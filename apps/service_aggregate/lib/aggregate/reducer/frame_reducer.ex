defmodule Aggregate.Reducer.FrameReducer do
  defstruct [:frame_people_count]

  def new(_opts) do
    %__MODULE__{
      frame_people_count: %{}
      # SampleImage1234: 15
      # SampleImage5678: 37
      # SampleImage9012: 1
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, stats) do
      %{t | frame_people_count: Map.get(stats, "frame_people_count")}
    end

    def reduce(_t, _event) do
      %{}
    end

    def merge(_t1, _t2) do
      %{}
    end

    def to_event_fields(_t) do
      []
    end
  end
end
