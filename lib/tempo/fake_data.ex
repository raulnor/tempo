defmodule Tempo.FakeData do
  def get_line_stack_data(cumulative \\ nil) do
    {
      ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      Enum.map(
        [
          %{
            name: "Email",
            values: [120, 132, 101, 134, 90, 230, 210]
          },
          %{
            name: "Union Ads",
            values: [220, 182, 191, 234, 290, 330, 310]
          },
          %{
            name: "Video Ads",
            values: [150, 232, 201, 154, 190, 330, 410]
          },
          %{
            name: "Direct",
            values: [320, 332, 301, 334, 390, 330, 320]
          },
          %{
            name: "Search Engine",
            values: [820, 932, 901, 934, 1290, 1330, 1320]
          }
        ],
        fn line_data ->
          values = Enum.map(line_data.values, &Float.round(&1 * :rand.uniform(), 0))
          values = (cumulative && Enum.scan(values, 0, &(&2 + &1))) || values

          %{line_data | values: values}
        end
      )
    }
  end

  def get_gauge_multi_title_data do
    %{
      good: Float.round(:rand.uniform() * 100, 2),
      better: Float.round(:rand.uniform() * 100, 2),
      perfect: Float.round(:rand.uniform() * 100, 2)
    }
  end

  def get_process_count, do: :erlang.system_info(:process_count)
end
