class Assistant::Function::GetDebtAnalysis < Assistant::Function
  include ActiveSupport::NumberHelper

  class << self
    def name
      "get_debt_analysis"
    end

    def description
      <<~INSTRUCTIONS
        Use this to analyze the user's debt situation and provide personalized debt payoff strategies.

        This function provides:
        - Comprehensive debt analysis across all liability accounts
        - Debt payoff strategies (snowball, avalanche, custom)
        - Projected payoff timelines and interest savings
        - Monthly payment recommendations
        - Debt-to-income ratios and financial health metrics

        Great for answering questions like:
        - How can I pay off my debt faster?
        - Which debt should I prioritize?
        - What's my total debt and monthly debt payments?
        - How long will it take to become debt-free?
        - What's my debt-to-income ratio?
      INSTRUCTIONS
    end
  end

  def call(params = {})
    strategy = params["strategy"] || "avalanche"
    extra_payment = params["extra_monthly_payment"]&.to_f || 0
    
    debt_accounts = family.accounts.liabilities.visible
    return { message: "No debt accounts found" } if debt_accounts.empty?

    debt_summary = analyze_debt_accounts(debt_accounts)
    payoff_strategies = calculate_payoff_strategies(debt_accounts, extra_payment)
    recommendations = generate_recommendations(debt_summary, payoff_strategies)

    {
      as_of_date: Date.current,
      debt_summary: debt_summary,
      payoff_strategies: payoff_strategies,
      recommendations: recommendations,
      insights: generate_insights(debt_summary, payoff_strategies)
    }
  end

  def params_schema
    build_schema(
      required: [],
      properties: {
        strategy: {
          type: "string",
          description: "Debt payoff strategy to analyze",
          enum: ["avalanche", "snowball", "custom"]
        },
        extra_monthly_payment: {
          type: "string",
          description: "Additional monthly payment amount to apply to debt payoff"
        }
      }
    )
  end

  private

  def analyze_debt_accounts(debt_accounts)
    total_balance = 0
    monthly_payments = 0
    accounts_data = []

    debt_accounts.each do |account|
      balance = account.balance.abs
      total_balance += balance

      # Estimate monthly payment (rough calculation)
      recent_payments = estimate_monthly_payment(account)
      monthly_payments += recent_payments

      # Estimate interest rate (if we can infer from payment patterns)
      estimated_rate = estimate_interest_rate(account, recent_payments, balance)

      accounts_data << {
        name: account.name,
        type: account.accountable_type,
        balance: format_money(balance),
        balance_raw: balance,
        estimated_monthly_payment: format_money(recent_payments),
        estimated_monthly_payment_raw: recent_payments,
        estimated_apr: estimated_rate ? "#{estimated_rate.round(2)}%" : "Unknown"
      }
    end

    {
      total_debt: format_money(total_balance),
      total_debt_raw: total_balance,
      total_monthly_payments: format_money(monthly_payments),
      total_monthly_payments_raw: monthly_payments,
      accounts: accounts_data.sort_by { |a| -a[:balance_raw] }
    }
  end

  def calculate_payoff_strategies(debt_accounts, extra_payment = 0)
    strategies = {}
    
    # Get account data with estimated rates and payments
    debt_data = debt_accounts.map do |account|
      balance = account.balance.abs
      monthly_payment = estimate_monthly_payment(account)
      estimated_rate = estimate_interest_rate(account, monthly_payment, balance) || 18.0 # Default if unknown
      
      {
        account: account,
        balance: balance,
        monthly_payment: monthly_payment,
        interest_rate: estimated_rate
      }
    end

    return strategies if debt_data.empty?

    # Avalanche strategy (highest interest first)
    avalanche_order = debt_data.sort_by { |d| -d[:interest_rate] }
    strategies["avalanche"] = calculate_payoff_timeline(avalanche_order, extra_payment, "Highest Interest Rate First")

    # Snowball strategy (lowest balance first)
    snowball_order = debt_data.sort_by { |d| d[:balance] }
    strategies["snowball"] = calculate_payoff_timeline(snowball_order, extra_payment, "Lowest Balance First")

    # Balanced strategy (mix of both)
    balanced_order = debt_data.sort_by { |d| d[:balance] / ([d[:interest_rate], 1].max) }
    strategies["balanced"] = calculate_payoff_timeline(balanced_order, extra_payment, "Balanced Approach")

    strategies
  end

  def calculate_payoff_timeline(ordered_debts, extra_payment, strategy_name)
    timeline = []
    total_interest_paid = 0
    current_debts = ordered_debts.map(&:dup)
    month = 0
    total_extra_applied = extra_payment

    while current_debts.any? { |d| d[:balance] > 0 }
      month += 1
      monthly_interest = 0

      # Apply regular payments and interest
      current_debts.each do |debt|
        next if debt[:balance] <= 0

        monthly_interest_charge = debt[:balance] * (debt[:interest_rate] / 100 / 12)
        monthly_interest += monthly_interest_charge
        total_interest_paid += monthly_interest_charge

        # Apply minimum payment
        payment = [debt[:monthly_payment], debt[:balance] + monthly_interest_charge].min
        debt[:balance] = debt[:balance] + monthly_interest_charge - payment
      end

      # Apply extra payment to first debt with balance
      if total_extra_applied > 0
        target_debt = current_debts.find { |d| d[:balance] > 0 }
        if target_debt
          extra_applied = [total_extra_applied, target_debt[:balance]].min
          target_debt[:balance] -= extra_applied
        end
      end

      # Record when debts are paid off
      current_debts.each do |debt|
        if debt[:balance] <= 0 && !debt[:paid_off_month]
          debt[:paid_off_month] = month
          timeline << {
            month: month,
            account: debt[:account].name,
            remaining_balance: format_money(0),
            message: "#{debt[:account].name} paid off!"
          }
        end
      end

      # Safety break for very long payoffs
      break if month > 600 # 50 years max
    end

    debt_free_month = current_debts.map { |d| d[:paid_off_month] || month }.max || month

    {
      strategy_name: strategy_name,
      months_to_debt_free: debt_free_month,
      years_to_debt_free: (debt_free_month / 12.0).round(1),
      total_interest_paid: format_money(total_interest_paid),
      total_interest_paid_raw: total_interest_paid,
      timeline: timeline.first(5) # Show first 5 payoffs
    }
  end

  def generate_recommendations(debt_summary, strategies)
    recommendations = []
    
    # Find best strategy
    best_strategy = strategies.min_by { |_, data| data[:total_interest_paid_raw] }
    if best_strategy
      strategy_name, strategy_data = best_strategy
      recommendations << "💡 The **#{strategy_data[:strategy_name]}** method could save you the most interest (#{strategy_data[:total_interest_paid]}) and get you debt-free in #{strategy_data[:years_to_debt_free]} years."
    end

    # High-interest debt warning
    debt_summary[:accounts].each do |account|
      if account[:estimated_apr].include?("Unknown")
        recommendations << "⚠️ Consider finding the exact interest rate for your #{account[:name]} to optimize your payoff strategy."
      end
    end

    # Debt-to-income insights
    monthly_income = estimate_monthly_income
    if monthly_income > 0
      debt_to_income = (debt_summary[:total_monthly_payments_raw] / monthly_income * 100).round(1)
      if debt_to_income > 40
        recommendations << "🚨 Your debt-to-income ratio is #{debt_to_income}% (above the recommended 36%). Consider increasing debt payments or finding additional income sources."
      elsif debt_to_income > 20
        recommendations << "⚡ Your debt-to-income ratio is #{debt_to_income}%. This is manageable but could be improved."
      else
        recommendations << "✅ Your debt-to-income ratio is #{debt_to_income}% - excellent debt management!"
      end
    end

    recommendations
  end

  def generate_insights(debt_summary, strategies)
    insights = {}
    
    # Calculate potential savings between strategies
    if strategies["avalanche"] && strategies["snowball"]
      avalanche_interest = strategies["avalanche"][:total_interest_paid_raw]
      snowball_interest = strategies["snowball"][:total_interest_paid_raw]
      savings = (snowball_interest - avalanche_interest).abs
      
      if avalanche_interest < snowball_interest
        insights[:strategy_comparison] = "The avalanche method could save you #{format_money(savings)} compared to the snowball method."
      else
        insights[:strategy_comparison] = "The snowball method could save you #{format_money(savings)} compared to the avalanche method."
      end
    end

    # Debt composition
    if debt_summary[:accounts].length > 1
      largest_debt = debt_summary[:accounts].first
      debt_percentage = (largest_debt[:balance_raw] / debt_summary[:total_debt_raw] * 100).round(1)
      insights[:debt_composition] = "Your #{largest_debt[:name]} represents #{debt_percentage}% of your total debt."
    end

    insights
  end

  def estimate_monthly_payment(account)
    # Look for payment transactions in the last 3 months
    recent_period = Period.custom(start_date: 3.months.ago, end_date: Date.current)
    transactions = account.transactions.in_period(recent_period).where('amount > 0') # Payments are positive for liabilities
    
    return 0 if transactions.empty?

    # Calculate average monthly payment
    total_payments = transactions.sum(:amount)
    months = [recent_period.months, 1].max
    (total_payments / months).round(2)
  end

  def estimate_interest_rate(account, monthly_payment, balance)
    return nil if monthly_payment <= 0 || balance <= 0

    # Very rough estimation based on payment-to-balance ratio
    # This is a simplified calculation and should be taken as an estimate
    monthly_rate = (monthly_payment / balance) - 0.01 # Assume some principal payment
    annual_rate = monthly_rate * 12 * 100

    # Keep within reasonable bounds for debt
    [[annual_rate, 3.0].max, 35.0].min
  end

  def estimate_monthly_income
    # Look for income transactions in the last 3 months
    recent_period = Period.custom(start_date: 3.months.ago, end_date: Date.current)
    income_transactions = family.transactions.visible.in_period(recent_period).where('amount < 0') # Income is negative
    
    return 0 if income_transactions.empty?

    total_income = income_transactions.sum(:amount).abs
    months = [recent_period.months, 1].max
    (total_income / months).round(2)
  end

  def format_money(amount)
    Money.new(amount.to_i, family.currency).format
  end
end
