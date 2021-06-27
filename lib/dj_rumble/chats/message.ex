defmodule DjRumble.Chats.Message do
  @moduledoc """
  Defines a Message model that can be used by a chat to create messages. Views
  may check data structures using this model.
  """
  import Algae

  alias DjRumble.Accounts.User, as: AccountUser
  alias DjRumble.Chats.Message
  alias DjRumble.Rooms.Video
  alias DjRumble.Rounds.Round

  @type id() :: String.t()
  @type round() :: Round.t()
  @type user() :: AccountUser
  @type video() :: Video

  defsum do
    defdata User do
      from :: Message.user() \\ %AccountUser{}
      message :: String.t() \\ ""
      timestamp :: String.t() \\ ""
    end

    defdata Video do
      video :: Message.video() \\ %Video{}
      added_by :: Message.user() \\ %AccountUser{}
      action :: :playing | :scheduled \\ :playing
      role :: :dj | :spectator | :system \\ :system
      args :: any() \\ nil
    end

    defdata Score do
      video :: Message.video() \\ %Video{}
      scored_by :: Message.user() \\ %AccountUser{}
      score_type :: :positive | :negative \\ :positive
      role :: :dj | :spectator \\ :spectator
      round :: Message.round() \\ %Round.InProgress{}
    end
  end

  @doc """
  Given a `type`, a `message`, a `user` and a `timezone`, returns a new `Message`.

  ## Examples

      iex> DjRumble.Chats.Message.create_message(
      ...>   :user_message,
      ...>   "Hello!",
      ...>   %DjRumble.Accounts.User{},
      ...>   "America/Buenos_Aires"
      ...> )
      %DjRumble.Chats.Message.User{
        message: "Hello!",
        timestamp: "13:51:48",
        user: #DjRumble.Accounts.User<...>
      }

  """
  def create_message(:user_message, message, user, timezone) do
    Message.User.new(user, message, timestamp(timezone))
  end

  def create_message(:video_message, video, user, {action, role, args}) do
    Message.Video.new(video, user, action, role, args)
  end

  def create_message(:video_message, video, user, action) do
    Message.Video.new(video, user, action)
  end

  def create_message(:score_message, video, user, {score_type, role, round}) do
    Message.Score.new(video, user, score_type, role, round)
  end

  @spec narrate(%{
          :__struct__ => DjRumble.Chats.Message.Score | DjRumble.Chats.Message.Video,
          :video => atom | %{:title => any, optional(any) => any},
          optional(any) => any
        }) :: any
  @doc """
  Given a `%Message{}`, returns a narrated event

  ## Examples

      iex> DjRumble.Chats.Message.narrate(
      ...>  %DjRumble.Chats.Message.Video{video: DjRumble.Rooms.Video{title: "my song"}},
      ...>  %DjRumble.Accounts.User{username: "some player"},
      ...>  action: :playing
      ...>)
      ["Now playing", "my song", "added_by", "some player"]

  """
  def narrate(%Message.Video{video: video, added_by: user, action: :playing}) do
    [
      "Now playing",
      {:video, "#{video.title}"},
      "added by",
      {:username, "#{user.username}"}
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :spectator,
        args: 0
      }) do
    [
      {:username, "#{user.username}"},
      "adds",
      {:video, "#{video.title}"},
      "and it's next to come"
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :spectator,
        args: args
      }) do
    [
      {:username, "#{user.username}"},
      "adds",
      {:video, "#{video.title}"},
      "and it's placed",
      {:args, "##{args}"},
      "in the queue"
    ]
  end

  def narrate(%Message.Video{video: video, added_by: user, action: :scheduled, role: :dj, args: 0}) do
    [
      "💿 Dj",
      {:username, "#{user.username}"},
      "casts",
      {:video, "#{video.title}"},
      "to be next in queue"
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :dj,
        args: args
      }) do
    [
      "💿 Dj",
      {:username, "#{user.username}"},
      "casts",
      {:video, "#{video.title}"},
      "to be",
      {:args, "##{args}"},
      "in queue"
    ]
  end

  def narrate(%Message.Score{round: %Round.InProgress{} = round} = message) do
    stage = Round.get_estimated_round_stage(round, 3)

    get_round_narrations_by_stage(message)
    |> Map.get(stage)
    |> pick_random_narration()
  end

  defp pick_random_narration(narrations) do
    Enum.at(narrations, Enum.random(0..(length(narrations) - 1)))
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :dj
  # Score type: :positive
  # Outcome: :continue
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :positive,
        role: :dj,
        round: %Round.InProgress{score: {positives, negatives}, outcome: :continue}
      }) do
    %{
      1 => [
        [
          "💿",
          username,
          "rushes to upvote itself 😳.",
          "This Dj really wants to own the queue..."
        ]
      ],
      2 => [
        [
          "💿 Dj",
          username,
          "listened for a while and votes in favor. Seems to be enjoying!",
          "Score says",
          "#{positives}",
          "in favor and",
          "#{negatives}",
          "against."
        ]
      ],
      3 => [
        [
          "Reaching the end",
          "💿 Dj",
          username,
          "secures the jam with a positive vote for",
          title,
          ". Score says",
          "#{positives}",
          "in favor and",
          "#{negatives}",
          "against."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :dj
  # Score type: :positive
  # Outcome: :thrown
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :positive,
        role: :dj,
        round: %Round.InProgress{score: {positives, negatives}, outcome: :thrown}
      }) do
    %{
      1 => [
        [
          "Just when",
          title,
          "started,",
          "💿 Dj",
          username,
          "quickly tries to secure an upvote to keep jamming the next round",
          "and leaves the score",
          "#{positives}",
          "in favor and",
          "#{negatives}",
          "against."
        ]
      ],
      2 => [
        [
          "In the midst of anxiety",
          "💿 Dj",
          username,
          "tries to fix the next round with an upvote. Still halfway to go while",
          title,
          "rumbles."
        ]
      ],
      3 => [
        [
          "Reaching the end",
          "💿 Dj",
          username,
          "tries to keep the cool with a positive vote but is not enough to win... Score says",
          "#{positives}",
          "in favor and",
          "#{negatives}",
          "against."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :dj
  # Score type: :negative
  # Outcome: :continue
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :negative,
        role: :dj,
        round: %Round.InProgress{score: {positives, _negatives}, outcome: :continue}
      }) do
    %{
      1 => [
        [
          title,
          "brings the bad memories to",
          "💿 Dj",
          username,
          "and inflicts a harmless downvote."
        ],
        [
          "💿 Dj",
          username,
          "takes a look at the score and crunches some 🍅."
        ]
      ],
      2 => [
        [
          "💿 Dj ",
          username,
          "turns around to pour the face in 🍅 soup but the crowd is actually enjoying",
          title,
          "."
        ]
      ],
      3 => [
        [
          "Near the end score for",
          title,
          "is closing",
          "#{positives}",
          "in favor that",
          username,
          "goes wild and gets gorged on folate, vitamin c and potassium 🍅."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :dj
  # Score type: :negative
  # Outcome: :thrown
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :negative,
        role: :dj,
        round: %Round.InProgress{score: {_positives, negatives}, outcome: :thrown}
      }) do
    %{
      1 => [
        [
          "💿 Dj",
          username,
          "just doesn't care and downvotes it's way out of the queue."
        ]
      ],
      2 => [
        ["Dj 💿", username, "👎", title, "."],
        ["Dj 💿", username, "takes a 🍅 bath while the score tells", "#{negatives}", "against."]
      ],
      3 => [
        [
          "💿 Dj",
          username,
          "is ashamed and poops on it's own video queue."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :spectator
  # Score type: :positive
  # Outcome: :continue
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :positive,
        role: :spectator,
        round: %Round.InProgress{score: {positives, _negatives}, outcome: :continue}
      }) do
    default = [username, "cheers 🎉 at", title, "."]

    %{
      1 => [
        default,
        [username, "rapidly gets in the mix and upvotes", title, "."]
      ],
      2 => [
        default,
        [
          "Spectator",
          username,
          "listened for a while and votes in favor. Seems to be enjoying",
          title,
          "."
        ]
      ],
      3 => [
        default,
        [
          "In the last minute",
          username,
          "slips out from the crown to cheer for",
          title,
          "🎉 and leaves the score",
          "#{positives}",
          "in favor."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :spectator
  # Score type: :positive
  # Outcome: :thrown
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :positive,
        role: :spectator,
        round: %Round.InProgress{score: {positives, negatives}, outcome: :thrown}
      }) do
    default = [username, "cheers 🎉 at", title, "."]

    %{
      1 => [
        default,
        [
          username,
          "shows",
          title,
          "some support but looks like the odds are against from the beginning. Score tells",
          "#{negatives}",
          "against and",
          "#{positives}",
          "in favor."
        ]
      ],
      2 => [
        default,
        [
          "Without a hint of shame",
          username,
          "cheers at",
          title,
          "despite the obvious boredom. Score tells",
          "#{negatives}",
          "against and",
          "#{positives}",
          "in favor."
        ]
      ],
      3 => [
        default,
        [
          username,
          "waited 'til the end to show some compasion.",
          title,
          "took a total of votes of",
          "#{negatives}",
          "."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :spectator
  # Score type: :negative
  # Outcome: :continue
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :negative,
        role: :spectator,
        round: %Round.InProgress{score: {positives, negatives}, outcome: :continue}
      }) do
    default = [username, "throws 🍅 at", title, "."]

    %{
      1 => [
        default,
        [
          "Out of nowhere",
          username,
          "swiftly throws a 🍅 over",
          title,
          "."
        ]
      ],
      2 => [
        default,
        [
          "Without a hint of shame",
          username,
          "throws a 🍅 but it's not enough to overcome",
          "#{positives}",
          "votes in favor",
          title,
          "."
        ],
        [
          username,
          "waited halfway at",
          title,
          "and intimidates the Dj with a shiny 🍅.",
          "Score is",
          "#{negatives}",
          "votes against."
        ]
      ],
      3 => [
        default,
        [
          "Spectator",
          username,
          "throws a rotten 🍅 that's been holding all this time! Still can't beat",
          "#{positives}",
          "votes in favor for",
          title,
          "."
        ]
      ]
    }
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :spectator
  # Score type: :negative
  # Outcome: :thrown
  # ----------------------------------------------------------------------------

  def get_round_narrations_by_stage(%Message.Score{
        video: %Video{title: title},
        scored_by: %AccountUser{username: username},
        score_type: :negative,
        role: :spectator,
        round: %Round.InProgress{score: {_positives, negatives}, outcome: :thrown}
      }) do
    default = [username, "throws 🍅 at", title, "."]

    %{
      1 => [
        default,
        [
          username,
          "quickly leaps into action and throws some fresh 🍅 at",
          title,
          "to put the score down to",
          "#{negatives}",
          "against."
        ]
      ],
      2 => [
        default,
        [
          "Spectator",
          username,
          "tirelessly strikes with a dripping 🍅 and leaves",
          title,
          "with",
          "#{negatives}",
          "votes against."
        ]
      ],
      3 => [
        default,
        [
          "Naughty",
          username,
          "takes the score down to",
          "#{negatives}",
          "by throwing a bag of decomposting 🍅 at",
          title,
          "."
        ]
      ]
    }
  end

  @doc """
  Given a timezone, returns a timestamp

  ## Examples

      iex> DjRumble.Chats.Message.timestamp("America/Buenos_Aires")
      "13:18:46"

  """
  @spec timestamp(binary) :: binary
  def timestamp(timezone) do
    DateTime.now(timezone, Tzdata.TimeZoneDatabase)
    |> elem(1)
    |> Time.to_string()
    |> String.split(".")
    |> hd
  end
end
