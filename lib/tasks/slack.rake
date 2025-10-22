namespace :slack do
  desc "Fetch messages from Slack channels (optional: specify channel_id)"
  task :fetch_messages, [:channel_id] => :environment do |t, args|
    fetcher = SlackMessageFetcher.new

    if args[:channel_id]
      puts "Fetching messages from channel #{args[:channel_id]}..."
      count = fetcher.fetch_channel(args[:channel_id])
      puts "✓ Fetched #{count} messages"
    else
      fetcher.fetch_all_channels
    end
  end
end
