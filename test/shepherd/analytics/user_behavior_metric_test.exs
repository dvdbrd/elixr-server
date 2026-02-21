defmodule Shepherd.Analytics.UserBehaviorMetricTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.Analytics.UserBehaviorMetric

  import Shepherd.AccountsFixtures

  # ---------------------------------------------------------------------------
  # UserBehaviorMetric.changeset/2
  # ---------------------------------------------------------------------------

  describe "changeset/2" do
    test "valid changeset with required user_id" do
      user = user_fixture()
      changeset = UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{user_id: user.id})
      assert changeset.valid?
    end

    test "invalid changeset when user_id is missing" do
      changeset = UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{})
      refute changeset.valid?
      assert changeset.errors[:user_id] != nil
    end

    test "invalid when question_completion_rate is greater than 1" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          question_completion_rate: Decimal.new("1.1")
        })

      refute changeset.valid?
      assert changeset.errors[:question_completion_rate] != nil
    end

    test "invalid when command_completion_rate is less than 0" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          command_completion_rate: Decimal.new("-0.1")
        })

      refute changeset.valid?
      assert changeset.errors[:command_completion_rate] != nil
    end

    test "invalid when dismissal_rate is out of 0-1 range" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          dismissal_rate: Decimal.new("2.0")
        })

      refute changeset.valid?
      assert changeset.errors[:dismissal_rate] != nil
    end

    test "invalid when procrastination_score is greater than 10" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          procrastination_score: Decimal.new("10.1")
        })

      refute changeset.valid?
      assert changeset.errors[:procrastination_score] != nil
    end

    test "invalid when procrastination_score is less than 0" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          procrastination_score: Decimal.new("-1.0")
        })

      refute changeset.valid?
      assert changeset.errors[:procrastination_score] != nil
    end

    test "invalid when preferred_communication_style is not in allowed list" do
      user = user_fixture()

      changeset =
        UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
          user_id: user.id,
          preferred_communication_style: "aggressive"
        })

      refute changeset.valid?
      assert changeset.errors[:preferred_communication_style] != nil
    end

    test "valid for all allowed communication styles" do
      user = user_fixture()

      for style <- ["direct", "encouraging", "harsh", "neutral"] do
        changeset =
          UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{
            user_id: user.id,
            preferred_communication_style: style
          })

        assert changeset.valid?, "Expected valid for style: #{style}"
      end
    end

    test "auto-sets updated_at on every changeset" do
      user = user_fixture()
      changeset = UserBehaviorMetric.changeset(%UserBehaviorMetric{}, %{user_id: user.id})
      refute is_nil(Ecto.Changeset.get_field(changeset, :updated_at))
    end
  end

  # ---------------------------------------------------------------------------
  # procrastinating?/1
  # ---------------------------------------------------------------------------

  describe "procrastinating?/1" do
    test "returns true when procrastination_score is >= 6.0" do
      metric = %UserBehaviorMetric{
        procrastination_score: Decimal.new("6.0"),
        overdue_command_count: 0,
        command_completion_rate: Decimal.new("0.8")
      }

      assert UserBehaviorMetric.procrastinating?(metric)
    end

    test "returns true when overdue_command_count is >= 3" do
      metric = %UserBehaviorMetric{
        procrastination_score: Decimal.new("1.0"),
        overdue_command_count: 3,
        command_completion_rate: Decimal.new("0.9")
      }

      assert UserBehaviorMetric.procrastinating?(metric)
    end

    test "returns true when command_completion_rate is < 0.5" do
      metric = %UserBehaviorMetric{
        procrastination_score: Decimal.new("2.0"),
        overdue_command_count: 0,
        command_completion_rate: Decimal.new("0.4")
      }

      assert UserBehaviorMetric.procrastinating?(metric)
    end

    test "returns false when all indicators are below threshold" do
      metric = %UserBehaviorMetric{
        procrastination_score: Decimal.new("3.0"),
        overdue_command_count: 1,
        command_completion_rate: Decimal.new("0.7")
      }

      refute UserBehaviorMetric.procrastinating?(metric)
    end

    test "defaults command_completion_rate to 1.0 when nil (not procrastinating)" do
      metric = %UserBehaviorMetric{
        procrastination_score: Decimal.new("2.0"),
        overdue_command_count: 0,
        command_completion_rate: nil
      }

      refute UserBehaviorMetric.procrastinating?(metric)
    end
  end

  # ---------------------------------------------------------------------------
  # calculate_procrastination_score/1
  # ---------------------------------------------------------------------------

  describe "calculate_procrastination_score/1" do
    test "returns 0.0 for default (all zeroes)" do
      score = UserBehaviorMetric.calculate_procrastination_score([])
      assert score == 0.0
    end

    test "overdue_count contributes 2.0 per overdue item, capped at 5.0" do
      # 2 overdue -> 4.0
      assert UserBehaviorMetric.calculate_procrastination_score(overdue_count: 2) == 4.0

      # 5 overdue would be 10.0 but overdue_score is capped at 5.0
      score = UserBehaviorMetric.calculate_procrastination_score(overdue_count: 5)
      assert score == 5.0
    end

    test "avg_delay_hours contributes delay_score capped at 3.0" do
      # 24 hours -> 1.0
      assert UserBehaviorMetric.calculate_procrastination_score(avg_delay_hours: 24) == 1.0

      # 72 hours -> 3.0 (max)
      assert UserBehaviorMetric.calculate_procrastination_score(avg_delay_hours: 72) == 3.0
    end

    test "dismissal_rate contributes dismissal_score of rate * 2" do
      # 0.5 rate -> 1.0
      assert UserBehaviorMetric.calculate_procrastination_score(dismissal_rate: 0.5) == 1.0
    end

    test "total score is capped at 10.0" do
      score =
        UserBehaviorMetric.calculate_procrastination_score(
          overdue_count: 10,
          avg_delay_hours: 200,
          dismissal_rate: 1.0
        )

      assert score == 10.0
    end

    test "combined score is sum of all components" do
      # overdue_score: min(2 * 2.0, 5.0) = 4.0
      # delay_score:   min(24 / 24.0, 3.0) = 1.0
      # dismissal_score: 0.5 * 2.0 = 1.0
      # total: 6.0
      score =
        UserBehaviorMetric.calculate_procrastination_score(
          overdue_count: 2,
          avg_delay_hours: 24,
          dismissal_rate: 0.5
        )

      assert score == 6.0
    end
  end

  # ---------------------------------------------------------------------------
  # recommend_communication_style/1
  # ---------------------------------------------------------------------------

  describe "recommend_communication_style/1" do
    test "returns harsh for score >= 8.0" do
      assert UserBehaviorMetric.recommend_communication_style(8.0) == "harsh"
      assert UserBehaviorMetric.recommend_communication_style(10.0) == "harsh"
    end

    test "returns direct for score >= 5.0 and < 8.0" do
      assert UserBehaviorMetric.recommend_communication_style(5.0) == "direct"
      assert UserBehaviorMetric.recommend_communication_style(7.9) == "direct"
    end

    test "returns encouraging for score >= 2.0 and < 5.0" do
      assert UserBehaviorMetric.recommend_communication_style(2.0) == "encouraging"
      assert UserBehaviorMetric.recommend_communication_style(4.9) == "encouraging"
    end

    test "returns neutral for score < 2.0" do
      assert UserBehaviorMetric.recommend_communication_style(0.0) == "neutral"
      assert UserBehaviorMetric.recommend_communication_style(1.9) == "neutral"
    end
  end
end
