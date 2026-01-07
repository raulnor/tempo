defmodule Tempo.HealthData.Formatter do
  @moduledoc """
  Translates Apple Health Kit identifiers to human-readable names.
  """

  @type_mappings %{
    # Body Measurements
    "HKQuantityTypeIdentifierBodyMass" => "Weight",
    "HKQuantityTypeIdentifierHeight" => "Height",
    "HKQuantityTypeIdentifierBodyMassIndex" => "BMI",
    "HKQuantityTypeIdentifierLeanBodyMass" => "Lean Body Mass",
    "HKQuantityTypeIdentifierBodyFatPercentage" => "Body Fat Percentage",
    "HKQuantityTypeIdentifierWaistCircumference" => "Waist Circumference",

    # Fitness
    "HKQuantityTypeIdentifierStepCount" => "Steps",
    "HKQuantityTypeIdentifierDistanceWalkingRunning" => "Walking + Running Distance",
    "HKQuantityTypeIdentifierDistanceCycling" => "Cycling Distance",
    "HKQuantityTypeIdentifierBasalEnergyBurned" => "Resting Energy",
    "HKQuantityTypeIdentifierActiveEnergyBurned" => "Active Energy",
    "HKQuantityTypeIdentifierFlightsClimbed" => "Flights Climbed",
    "HKQuantityTypeIdentifierNikeFuel" => "Nike Fuel",
    "HKQuantityTypeIdentifierAppleExerciseTime" => "Exercise Minutes",
    "HKQuantityTypeIdentifierPushCount" => "Pushes",
    "HKQuantityTypeIdentifierDistanceWheelchair" => "Wheelchair Distance",
    "HKQuantityTypeIdentifierSwimmingStrokeCount" => "Swimming Strokes",
    "HKQuantityTypeIdentifierDistanceSwimming" => "Swimming Distance",
    "HKQuantityTypeIdentifierDistanceDownhillSnowSports" => "Downhill Snow Sports Distance",
    "HKQuantityTypeIdentifierRunningPower" => "Running Power",

    # Vitals
    "HKQuantityTypeIdentifierHeartRate" => "Heart Rate",
    "HKQuantityTypeIdentifierBodyTemperature" => "Body Temperature",
    "HKQuantityTypeIdentifierBasalBodyTemperature" => "Basal Body Temperature",
    "HKQuantityTypeIdentifierBloodPressureSystolic" => "Blood Pressure (Systolic)",
    "HKQuantityTypeIdentifierBloodPressureDiastolic" => "Blood Pressure (Diastolic)",
    "HKQuantityTypeIdentifierRespiratoryRate" => "Respiratory Rate",
    "HKQuantityTypeIdentifierRestingHeartRate" => "Resting Heart Rate",
    "HKQuantityTypeIdentifierWalkingHeartRateAverage" => "Walking Heart Rate",
    "HKQuantityTypeIdentifierHeartRateVariabilitySDNN" => "Heart Rate Variability",
    "HKQuantityTypeIdentifierOxygenSaturation" => "Blood Oxygen",
    "HKQuantityTypeIdentifierPeripheralPerfusionIndex" => "Perfusion Index",
    "HKQuantityTypeIdentifierBloodGlucose" => "Blood Glucose",
    "HKQuantityTypeIdentifierAppleSleepingWristTemperature" => "Wrist Temperature",

    # Nutrition
    "HKQuantityTypeIdentifierDietaryFatTotal" => "Dietary Fat",
    "HKQuantityTypeIdentifierDietaryFatPolyunsaturated" => "Polyunsaturated Fat",
    "HKQuantityTypeIdentifierDietaryFatMonounsaturated" => "Monounsaturated Fat",
    "HKQuantityTypeIdentifierDietaryFatSaturated" => "Saturated Fat",
    "HKQuantityTypeIdentifierDietaryCholesterol" => "Cholesterol",
    "HKQuantityTypeIdentifierDietarySodium" => "Sodium",
    "HKQuantityTypeIdentifierDietaryCarbohydrates" => "Carbohydrates",
    "HKQuantityTypeIdentifierDietaryFiber" => "Fiber",
    "HKQuantityTypeIdentifierDietarySugar" => "Sugar",
    "HKQuantityTypeIdentifierDietaryEnergyConsumed" => "Calories",
    "HKQuantityTypeIdentifierDietaryProtein" => "Protein",
    "HKQuantityTypeIdentifierDietaryVitaminA" => "Vitamin A",
    "HKQuantityTypeIdentifierDietaryVitaminB6" => "Vitamin B6",
    "HKQuantityTypeIdentifierDietaryVitaminB12" => "Vitamin B12",
    "HKQuantityTypeIdentifierDietaryVitaminC" => "Vitamin C",
    "HKQuantityTypeIdentifierDietaryVitaminD" => "Vitamin D",
    "HKQuantityTypeIdentifierDietaryVitaminE" => "Vitamin E",
    "HKQuantityTypeIdentifierDietaryVitaminK" => "Vitamin K",
    "HKQuantityTypeIdentifierDietaryCalcium" => "Calcium",
    "HKQuantityTypeIdentifierDietaryIron" => "Iron",
    "HKQuantityTypeIdentifierDietaryThiamin" => "Thiamin",
    "HKQuantityTypeIdentifierDietaryRiboflavin" => "Riboflavin",
    "HKQuantityTypeIdentifierDietaryNiacin" => "Niacin",
    "HKQuantityTypeIdentifierDietaryFolate" => "Folate",
    "HKQuantityTypeIdentifierDietaryBiotin" => "Biotin",
    "HKQuantityTypeIdentifierDietaryPantothenicAcid" => "Pantothenic Acid",
    "HKQuantityTypeIdentifierDietaryPhosphorus" => "Phosphorus",
    "HKQuantityTypeIdentifierDietaryIodine" => "Iodine",
    "HKQuantityTypeIdentifierDietaryMagnesium" => "Magnesium",
    "HKQuantityTypeIdentifierDietaryZinc" => "Zinc",
    "HKQuantityTypeIdentifierDietarySelenium" => "Selenium",
    "HKQuantityTypeIdentifierDietaryCopper" => "Copper",
    "HKQuantityTypeIdentifierDietaryManganese" => "Manganese",
    "HKQuantityTypeIdentifierDietaryChromium" => "Chromium",
    "HKQuantityTypeIdentifierDietaryMolybdenum" => "Molybdenum",
    "HKQuantityTypeIdentifierDietaryChloride" => "Chloride",
    "HKQuantityTypeIdentifierDietaryPotassium" => "Potassium",
    "HKQuantityTypeIdentifierDietaryCaffeine" => "Caffeine",
    "HKQuantityTypeIdentifierDietaryWater" => "Water",

    # Sleep
    "HKCategoryTypeIdentifierSleepAnalysis" => "Sleep",

    # Mindfulness
    "HKCategoryTypeIdentifierMindfulSession" => "Mindful Minutes",

    # UV Exposure
    "HKQuantityTypeIdentifierUVExposure" => "UV Exposure",

    # Audio
    "HKQuantityTypeIdentifierEnvironmentalAudioExposure" => "Environmental Audio Exposure",
    "HKQuantityTypeIdentifierHeadphoneAudioExposure" => "Headphone Audio Exposure",

    # Mobility
    "HKQuantityTypeIdentifierWalkingSpeed" => "Walking Speed",
    "HKQuantityTypeIdentifierWalkingStepLength" => "Walking Step Length",
    "HKQuantityTypeIdentifierWalkingAsymmetryPercentage" => "Walking Asymmetry",
    "HKQuantityTypeIdentifierWalkingDoubleSupportPercentage" => "Walking Double Support",
    "HKQuantityTypeIdentifierSixMinuteWalkTestDistance" => "Six-Minute Walk",
    "HKQuantityTypeIdentifierStairAscentSpeed" => "Stair Ascent Speed",
    "HKQuantityTypeIdentifierStairDescentSpeed" => "Stair Descent Speed",

    # Hearing
    "HKDataTypeIdentifierAudioExposureEvent" => "Audio Exposure Event",

    # Apple
    "HKQuantityTypeIdentifierAppleWalkingSteadiness" => "Walking Steadiness"
  }

  @doc """
  Translates an Apple Health type identifier to a human-readable name.
  Returns the original identifier if no translation is found.

  ## Examples

      iex> humanize("HKQuantityTypeIdentifierBodyMass")
      "Weight"

      iex> humanize("UnknownType")
      "UnknownType"

  """
  def humanize(health_kit_identifier) do
    Map.get(@type_mappings, health_kit_identifier, health_kit_identifier)
  end

  @doc """
  Returns all known type mappings.
  """
  def all_mappings, do: @type_mappings

  @doc """
  Formats a quantity value based on the sample type.
  Handles percentages specially, falls back to 3 decimal places for others.

  ## Examples

      iex> format_quantity(0.856, "HKQuantityTypeIdentifierBodyFatPercentage")
      "85.6%"

      iex> format_quantity(123.456789, "HKQuantityTypeIdentifierBodyMass")
      "123.457"

      iex> format_quantity(100.0, "HKQuantityTypeIdentifierStepCount")
      "100"

  """
  def format_quantity(nil, _type), do: ""

  def format_quantity(quantity, type) when is_float(quantity) or is_integer(quantity) do
    cond do
      # Percentage types - multiply by 100 and add % sign
      is_percentage_type?(type) ->
        formatted = :erlang.float_to_binary(quantity * 100.0, decimals: 1)
        |> String.replace(~r/\.?0+$/, "")
        "#{formatted} %"

      # Default - 3 decimal places, remove trailing zeros
      true ->
        :erlang.float_to_binary(quantity * 1.0, decimals: 3)
        |> String.replace(~r/\.?0+$/, "")
    end
  end

  # Helper to identify percentage types
  defp is_percentage_type?(type) do
    type in [
      "HKQuantityTypeIdentifierBodyFatPercentage",
      "HKQuantityTypeIdentifierOxygenSaturation",
      "HKQuantityTypeIdentifierWalkingAsymmetryPercentage",
      "HKQuantityTypeIdentifierWalkingDoubleSupportPercentage",
      "HKQuantityTypeIdentifierAppleWalkingSteadiness"
    ]
  end

  @doc """
  Formats a UTC datetime to Eastern time with a readable format.

  ## Examples

      iex> format_date(~U[2024-01-15 14:30:00Z])
      "Jan 15, 2024 9:30 AM"

  """
  def format_date(nil), do: ""

  def format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("America/New_York")
    |> Calendar.strftime("%b %-d, %Y %-I:%M %p")
  end

  @doc """
  Formats an end date, showing "--" if it equals the start date.

  ## Examples

      iex> format_end_date(~U[2024-01-15 14:30:00Z], ~U[2024-01-15 14:30:00Z])
      "--"

      iex> format_end_date(~U[2024-01-15 14:30:00Z], ~U[2024-01-15 15:30:00Z])
      "Jan 15, 2024 10:30 AM"

  """
  def format_end_date(start_date, end_date) do
    if start_date == end_date do
      "--"
    else
      format_date(end_date)
    end
  end
end
