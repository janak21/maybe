# Personal Finance Coach

Your personalized version of Maybe Finance with enhanced AI coaching capabilities.

## 🚀 Features

### Base Maybe Finance Features
- **Complete Financial Tracking**: Track all accounts (checking, savings, credit cards, loans, investments, crypto)
- **Transaction Management**: Automatic categorization, merchant detection, and tagging
- **Multi-currency Support**: Handle multiple currencies with automatic exchange rates
- **Bank Integration**: Connect accounts via Plaid for automatic transaction imports
- **Investment Tracking**: Portfolio management with real-time holdings and performance
- **Net Worth Analysis**: Historical balance tracking and trend analysis
- **Budgeting**: Monthly budget creation and tracking with category-based insights

### 🤖 Enhanced AI Personal Finance Coach
- **Debt Analysis & Payoff Strategies**: Personalized debt payoff plans (avalanche, snowball, balanced)
- **Financial Health Metrics**: Debt-to-income ratios, savings rate calculations
- **Intelligent Recommendations**: Actionable insights based on your actual financial data
- **Smart Questioning**: AI that asks follow-up questions to help you understand your finances
- **Comprehensive Analysis**: Income/expense insights, spending pattern analysis

## 🏃‍♂️ Quick Start

### Option 1: Local Development

1. **Prerequisites**:
   ```bash
   # Install Ruby 3.4.4, PostgreSQL 16, and Redis
   brew install postgresql@16 redis rbenv
   rbenv install 3.4.4
   ```

2. **Setup**:
   ```bash
   git clone https://github.com/janak21/maybe.git
   cd maybe
   git checkout personal-finance-coach
   cp .env.local.example .env.local
   bin/setup
   ```

3. **Configure Environment**:
   - Get an OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys)
   - Add it to `.env.local`: `OPENAI_API_KEY=your_key_here`

4. **Start Services**:
   ```bash
   brew services start postgresql@16
   brew services start redis
   bin/dev
   ```

5. **Access**: Open [http://localhost:3000](http://localhost:3000)
   - Login: `user@maybe.local`
   - Password: `password`

### Option 2: Docker Deployment (Recommended)

1. **Prerequisites**:
   ```bash
   # Install Docker and Docker Compose
   brew install docker docker-compose
   ```

2. **Setup**:
   ```bash
   git clone https://github.com/janak21/maybe.git
   cd maybe
   git checkout personal-finance-coach
   cp .env.production .env.production.local
   ```

3. **Configure Environment**:
   ```bash
   # Edit .env.production.local with your values
   OPENAI_API_KEY=your_openai_key
   SECRET_KEY_BASE=$(openssl rand -hex 64)
   ```

4. **Deploy**:
   ```bash
   docker-compose -f docker-compose.personal.yml --env-file .env.production.local up -d
   ```

5. **Access**: Open [http://localhost:3000](http://localhost:3000)

## 💬 Using Your AI Finance Coach

Once set up, you can chat with your AI finance coach about:

- **Debt Management**: "How can I pay off my credit cards faster?"
- **Spending Analysis**: "What are my biggest expense categories this month?"
- **Financial Health**: "What's my debt-to-income ratio?"
- **Goal Setting**: "How long will it take to save $10,000?"
- **Budget Insights**: "Where can I cut expenses?"

The AI has access to all your financial data and provides personalized recommendations based on your actual situation.

## 🛠 Customization

### Adding New AI Functions

1. Create new function in `app/models/assistant/function/`:
   ```ruby
   class Assistant::Function::YourFunction < Assistant::Function
     # Implementation
   end
   ```

2. Add to assistant configuration in `app/models/assistant/configurable.rb`

3. Restart the application

### Modifying AI Personality

Edit the instructions in `app/models/assistant/configurable.rb` to change how your AI coach responds.

## 🔒 Security & Privacy

- **Self-Hosted**: All your financial data stays on your own infrastructure
- **Open Source**: Full transparency - you can review all code
- **Encrypted**: Database encryption and secure API communication
- **No Tracking**: No external analytics or data sharing

## 📊 Data Import

### Manual Import
- CSV imports from any bank or financial institution
- Manual account and transaction entry
- Bulk import tools for historical data

### Automatic Import (Optional)
- Plaid integration for US/Canada bank connections
- Real-time transaction sync
- Investment account integration

## 🔧 Maintenance

### Backups
```bash
# Database backup
docker exec [container_name] pg_dump -U maybe maybe_production > backup.sql

# Restore backup
docker exec -i [container_name] psql -U maybe maybe_production < backup.sql
```

### Updates
```bash
git pull origin personal-finance-coach
docker-compose -f docker-compose.personal.yml build --no-cache
docker-compose -f docker-compose.personal.yml up -d
```

## 🤝 Contributing

This is your personal fork! Feel free to:
- Add new AI functions for specific financial goals
- Customize the UI/UX to your preferences  
- Add integrations with your preferred financial services
- Share improvements back to the main Maybe project

## 📝 License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of [Maybe Finance](https://github.com/maybe-finance/maybe)
- AI capabilities powered by OpenAI
- Multi-currency data provided by Synth Finance

---

**Happy Budgeting! 💰**
