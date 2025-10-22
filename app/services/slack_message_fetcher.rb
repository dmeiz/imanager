class SlackMessageFetcher
  INITIAL_FETCH_DAYS = 30
  MAX_RETRIES = 3
  RETRY_DELAY = 2 # seconds

  def initialize
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
    @client = Slack::Web::Client.new
  end

  def fetch_all_channels
    puts "Fetching messages from Slack..."

    channels = discover_channels
    puts "Discovered #{channels.count} channels\n\n"

    total_messages = 0
    channels.each_with_index do |channel, index|
      count = fetch_channel(channel.channel_id)
      total_messages += count
      puts "[#{index + 1}/#{channels.count}] ##{channel.channel_name} (#{channel.channel_id}): #{count} new messages"
    end

    puts "\n✓ Fetched #{total_messages} total messages from #{channels.count} channels"
  end

  def fetch_channel(channel_id)
    channel = SlackChannel.find_by(channel_id: channel_id)

    unless channel
      puts "Channel #{channel_id} not found in database. Run without parameters to discover channels first."
      return 0
    end

    oldest_timestamp = calculate_oldest_timestamp(channel)
    messages = fetch_messages_from_slack(channel_id, oldest_timestamp)

    return 0 if messages.empty?

    ActiveRecord::Base.transaction do
      messages.each do |message|
        store_message(message, channel_id)
      end

      channel.update!(last_fetched_at: Time.current)
    end

    messages.count
  rescue Slack::Web::Api::Errors::SlackError => e
    handle_slack_error(e, channel_id)
    0
  rescue StandardError => e
    Rails.logger.error("Error fetching messages from channel #{channel_id}: #{e.message}")
    0
  end

  private

  def discover_channels
    response = @client.conversations_list(
      types: 'public_channel,private_channel',
      exclude_archived: true
    )

    channels = response.channels.select { |c| c.is_member }

    channels.map do |slack_channel|
      SlackChannel.find_or_create_by!(channel_id: slack_channel.id) do |channel|
        channel.channel_name = slack_channel.name
      end.tap do |channel|
        # Update name if changed
        if channel.channel_name != slack_channel.name
          channel.update!(channel_name: slack_channel.name)
        end
      end
    end
  end

  def calculate_oldest_timestamp(channel)
    if channel.last_fetched_at
      channel.last_fetched_at.to_i
    else
      INITIAL_FETCH_DAYS.days.ago.to_i
    end
  end

  def fetch_messages_from_slack(channel_id, oldest_timestamp)
    all_messages = []
    cursor = nil

    loop do
      params = {
        channel: channel_id,
        oldest: oldest_timestamp,
        limit: 1000
      }
      params[:cursor] = cursor if cursor

      response = with_retry do
        @client.conversations_history(params)
      end

      all_messages.concat(response.messages)

      break unless response.has_more
      cursor = response.response_metadata.next_cursor
    end

    all_messages
  end

  def store_message(message, channel_id)
    # Skip messages without required fields
    return unless message.text && message.ts && message.user

    person = find_or_create_person(message.user)
    return unless person

    Message.find_or_create_by!(slack_message_id: message.ts) do |msg|
      msg.channel_id = channel_id
      msg.user_id = person.id
      msg.content = message.text
      msg.timestamp = Time.at(message.ts.to_f)
      msg.thread_ts = message.thread_ts if message.thread_ts
    end
  rescue ActiveRecord::RecordInvalid => e
    # Message likely already exists due to unique constraint
    Rails.logger.debug("Skipping duplicate message #{message.ts}: #{e.message}")
  end

  def find_or_create_person(slack_user_id)
    Person.find_by(slack_user_id: slack_user_id) || create_person_from_slack(slack_user_id)
  end

  def create_person_from_slack(slack_user_id)
    user_info = with_retry do
      @client.users_info(user: slack_user_id)
    end

    Person.create!(
      slack_user_id: slack_user_id,
      name: user_info.user.real_name || user_info.user.name
    )
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Failed to fetch user info for #{slack_user_id}: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Error creating person for #{slack_user_id}: #{e.message}")
    nil
  end

  def with_retry(retries = MAX_RETRIES, &block)
    attempt = 0
    begin
      attempt += 1
      block.call
    rescue Slack::Web::Api::Errors::TooManyRequestsError => e
      if attempt < retries
        sleep_time = e.retry_after || RETRY_DELAY ** attempt
        Rails.logger.warn("Rate limited. Retrying in #{sleep_time}s...")
        sleep(sleep_time)
        retry
      else
        raise
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      if attempt < retries
        sleep_time = RETRY_DELAY ** attempt
        Rails.logger.warn("Network error. Retrying in #{sleep_time}s...")
        sleep(sleep_time)
        retry
      else
        raise
      end
    end
  end

  def handle_slack_error(error, channel_id)
    case error.message
    when /not_in_channel/
      Rails.logger.warn("Not a member of channel #{channel_id}. Skipping.")
    when /channel_not_found/
      Rails.logger.warn("Channel #{channel_id} not found. May have been deleted.")
    else
      Rails.logger.error("Slack API error for channel #{channel_id}: #{error.message}")
    end
  end
end
