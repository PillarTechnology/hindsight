defmodule Aggregate.TestHelpers.FrameEventGenerator do

  def generate(frame, opts \\ %{}) do
    %{
      "BoundingBox" => [0.5049, 0.0129, 0.5268, 0.1108],
      "Classification" => Map.get(opts, :classification, ["person"]),
      "Confidence" => 0.761,
      "Context" => "00AA00AA00AA00AA",
      "EventID" => "42539522",
      "MessageType" => "1011",
      "Module" => "4000",
      "SampleImage" => "/ingestion/00AA00AA00AA00AA/frame/#{frame}",
      "SampleObject" => "/ingestion/00AA00AA00AA00AA/frame/#{frame}/[0.5049,0.0129,0.5268,0.1108]",
      "Sequence" => 0,
      "Timestamp" => NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()
  }
  end
end
