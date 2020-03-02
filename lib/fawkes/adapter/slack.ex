defmodule Fawkes.Adapter.Slack do
  use Slack

  @behaviour Fawkes.Adapter

  alias Fawkes.EventProducer
  alias Fawkes.Event.{
    Message,
    Mention,
    ReactionAdded,
    ReactionRemoved,
    ChannelJoined,
    ChannelLeft,
  }

  require Logger

  def child_spec(opts) do
    token = opts[:token] || raise ArgumentError, "Requires a slack token"
    producer = opts[:producer] || raise ArgumentError, "Requires a producer"
    slack_opts = Map.new(opts[:adapter_options])

    args = [
      __MODULE__, # The callback module to use,
      [producer: producer], # Initial arguments
      token, # Slack API Token
      slack_opts, # Name and other options. We need this so we can find our adapter later.
    ]

    %{
      id: __MODULE__,
      start: {Slack.Bot, :start_link, args},
    }
  end

  def say(event, text) do
    message_adapter(event, {:say, event, text})
  end

  def reply(event, text) do
    message_adapter(event, {:reply, event, text})
  end

  def code(event, text) do
    message_adapter(event, {:code, event, text})
  end

  def message_channel(event, text) do
    message_adapter(event, {:message_channel, event, text})
  end

  defp message_adapter(event, msg) do
    send(Process.whereis(event.bot.adapter_name), msg)
  end

  def handle_connect(slack, state) do
    Logger.debug "Connected as #{slack.me.name}"
    EventProducer.set_bot_name(state[:producer], "@#{slack.me.id}")
    {:ok, state}
  end

  def handle_event(event, slack, state) do
    event = build_event(event, slack, state)

    unless event == nil do
      Fawkes.EventProducer.notify(state[:producer], event)
    end

    {:ok, state}
  end
  def handle_event(_event, _, state) do
    {:ok, state}
  end

  def handle_info({:say, msg, text}, slack, state) do
    send_message(text, msg.channel.id, slack)
    {:ok, state}
  end

  def handle_info({:reply, msg, text}, slack, state) do
    text = "<@#{msg.user.id}> #{text}"
    send_message(text, msg.channel.id, slack)
    {:ok, state}
  end

  def handle_info({:code, event, text}, slack, state) do
    text = """
    ```
    #{text}
    ```
    """
    send_message(text, event.channel.id, slack)
    {:ok, state}
  end

  def handle_info({:message_channel, event, text}, slack, state) do
    text = "<!here> #{text}"
    send_message(text, event.channel.id, slack)
    {:ok, state}
  end

  def handle_info(msg, _, state) do
    Logger.debug(fn -> "Unhandled message: #{inspect msg}" end)
    {:ok, state}
  end

  defp channel(%{channel: id}, slack) do
    case slack.channels[id] do
      nil ->
        %{id: id, name: ""}

      channel ->
        %{id: id, name: channel}
    end
  end

  defp user(%{user: id}, slack) do
    # We don't guard here because we should never get a message from a user we
    # don't know.
    user = slack.users[id]

    name = case user.profile.display_name do
      "" -> user.name
      name -> name
    end

    %{
      id: id,
      name: name
    }
  end

  defp build_event(event, slack, state) do
    case event.type do
      "message" ->
        user    = user(event, slack)
        channel = channel(event, slack)
        %Message{
          bot: self(),
          text: replace_links(event.text),
          user: user,
          channel: channel,
        }

      "reaction_added" ->
        %ReactionAdded{
          # handler: __MODULE__,
          bot: self(),
          reaction: event.reaction,
          user: user(event, slack),
          # TODO - Add the other fields here
        }

      "reaction_removed" ->
        %ReactionRemoved{
          # handler: __MODULE__,
          # bot: self(),
          reaction: event.reaction,
          user: user(event, slack),
          # TODO - Add the other fields here
        }

      _ ->
        nil
    end
  end

  @link_regex ~r/<([^>|]+)>/
  defp replace_links(text) do
    Regex.replace(@link_regex, text, fn _, link -> link end)
  end
end
