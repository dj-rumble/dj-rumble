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
      action :: :playing | :scheduled | :finished \\ :playing
      role :: :dj | :spectator | :system \\ :system
      args :: any() \\ nil
      narration :: [String.t()] \\ []
    end

    defdata Score do
      video :: Message.video() \\ %Video{}
      scored_by :: Message.user() \\ %AccountUser{}
      score_type :: :positive | :negative \\ :positive
      role :: :dj | :spectator \\ :spectator
      round :: Message.round() \\ %Round.InProgress{}
      narration :: [String.t()] \\ []
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

  def create_message(:video_message, video, user, {:finished = action, role, args}) do
    Message.Video.new(video, user, action, role, args)
    |> Message.narrate()
  end

  def create_message(:video_message, video, user, {action, role, args}) do
    Message.Video.new(video, user, action, role, args)
  end

  def create_message(:video_message, video, user, action) do
    Message.Video.new(video, user, action)
  end

  def create_message(:score_message, video, user, {score_type, role, round}) do
    Message.Score.new(video, user, score_type, role, round)
    |> Message.narrate()
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

  def narrate(%Message.Video{action: :finished} = message) do
    narration =
      get_finished_round_narrations(message)
      |> pick_random_narration()

    %Message.Video{message | narration: narration}
  end

  def narrate(%Message.Video{video: video, added_by: user, action: :scheduled, role: :dj, args: 0}) do
    [
      {:emoji, "💿"},
      "Dj",
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
      {:emoji, "💿"},
      "Dj",
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

    narration =
      get_round_narrations_by_stage(message)
      |> Map.get(stage)
      |> pick_random_narration()

    %Message.Score{message | narration: narration}
  end

  # ----------------------------------------------------------------------------
  # Finished Round Narrations
  # Role: :spectator
  # ----------------------------------------------------------------------------

  defp get_text(1, {singular, _plural}), do: singular
  defp get_text(_, {_singular, plural}), do: plural

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        added_by: %AccountUser{username: username},
        action: :finished,
        role: :spectator,
        args: {{positives, _negatives}, :continue, 0}
      }) do
    [
      [
        {:video, "#{title}"},
        "heated it up and got",
        {:positive_score, "#{positives}"},
        "likes.",
        {:username, "#{username}"},
        "haven't scheduled a jam and some other Dj is playing next."
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        action: :finished,
        role: :spectator,
        args: {_score, :thrown, 0}
      }) do
    [
      [
        "People really didn't get on with",
        {:video, "#{title}"},
        "Some other Dj is going to play next."
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        added_by: %AccountUser{username: username},
        action: :finished,
        role: :spectator,
        args: {{positives, _negatives}, :continue, next_tracks_count}
      }) do
    [
      [
        {:video, "#{title}"},
        "heated it up and got",
        {:positive_score, "#{positives}"},
        "likes.",
        next_tracks_count,
        "#{get_text(next_tracks_count, {"track", "tracks"})} added by",
        {:username, "#{username}"},
        "come next in queue."
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        added_by: %AccountUser{username: username},
        action: :finished,
        role: :spectator,
        args: {_score, :thrown, next_tracks_count}
      }) do
    [
      [
        "People really didn't get on with",
        {:video, "#{title}"},
        "Some other Dj is going to play next.",
        next_tracks_count,
        "#{get_text(next_tracks_count, {"track", "tracks"})} added by",
        {:username, "#{username}"},
        "#{get_text(next_tracks_count, {"is", "are"})} moved to the end of the queue."
      ]
    ]
  end

  # ----------------------------------------------------------------------------
  # Narrations
  # Role: :dj
  # Score type: :positive
  # Outcome: :thrown
  # ----------------------------------------------------------------------------

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        action: :finished,
        role: :dj,
        args: {{positives, negatives}, :continue, 0}
      }) do
    [
      [
        {:positive_score, "#{positives}"},
        "people liked",
        {:video, title},
        "and",
        {:negative_score, "#{negatives}"},
        "voted against.",
        "You haven't added more tracks, what's your next choice?"
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        action: :finished,
        role: :dj,
        args: {{positives, negatives}, :thrown, 0}
      }) do
    [
      [
        {:positive_score, "#{positives}"},
        "people liked",
        {:video, title},
        "and got",
        {:negative_score, "#{negatives}"},
        "thumbs down.",
        "You've no more videos added."
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        action: :finished,
        role: :dj,
        args: {{positives, negatives}, :continue, next_tracks_count}
      }) do
    [
      [
        {:positive_score, "#{positives}"},
        "people liked",
        {:video, title},
        "and got",
        {:negative_score, "#{negatives}"},
        "thumbs down.",
        {next_tracks_count},
        "of your tracks continue in queue."
      ]
    ]
  end

  def get_finished_round_narrations(%Message.Video{
        video: %Video{title: title},
        action: :finished,
        role: :dj,
        args: {{positives, negatives}, :thrown, next_tracks_count}
      }) do
    [
      [
        {:positive_score, "#{positives}"},
        "people liked",
        {:video, title},
        "and got",
        {:negative_score, "#{negatives}"},
        "thumbs down.",
        {next_tracks_count},
        "of your tracks were moved to the end of the queue."
      ]
    ]
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
          {:emoji, "💿"},
          username,
          "rushes to upvote itself",
          {:emoji, "😳"},
          "This Dj really wants to own the queue..."
        ]
      ],
      2 => [
        [
          {:emoji, "💿"},
          "Dj",
          username,
          "listened for a while and votes in favor. Seems to be enjoying!",
          "Score says",
          {:positive_score, "#{positives}"},
          "in favor and",
          {:negative_score, "#{negatives}"},
          "against."
        ]
      ],
      3 => [
        [
          "Reaching the end",
          {:emoji, "💿"},
          "Dj",
          username,
          "secures the jam with a positive vote for",
          {:light_video, title},
          ". Score says",
          {:positive_score, "#{positives}"},
          "in favor and",
          {:negative_score, "#{negatives}"},
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
          {:light_video, title},
          "started,",
          {:emoji, "💿"},
          "Dj",
          username,
          "quickly tries to secure an upvote to keep jamming the next round",
          "and leaves the score",
          {:positive_score, "#{positives}"},
          "in favor and",
          {:negative_score, "#{negatives}"},
          "against."
        ]
      ],
      2 => [
        [
          "In the midst of anxiety",
          {:emoji, "💿"},
          "Dj",
          username,
          "tries to fix the next round with an upvote. Still halfway to go while",
          {:light_video, title},
          "rumbles."
        ]
      ],
      3 => [
        [
          "Reaching the end",
          {:emoji, "💿"},
          "Dj",
          username,
          "tries to keep the cool with a positive vote but is not enough to win... Score says",
          {:positive_score, "#{positives}"},
          "in favor and",
          {:negative_score, "#{negatives}"},
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
          {:light_video, title},
          "brings the bad memories to",
          {:emoji, "💿"},
          "Dj",
          username,
          "and inflicts a harmless downvote."
        ],
        [
          {:emoji, "💿"},
          "Dj",
          username,
          "takes a look at the score and crunches some",
          {:emoji, "🍅"},
          "."
        ]
      ],
      2 => [
        [
          {:emoji, "💿"},
          "Dj",
          username,
          "turns around to pour the face in",
          {:emoji, "🍅"},
          "soup but the crowd is actually enjoying",
          {:light_video, title},
          "."
        ]
      ],
      3 => [
        [
          "Near the end score for",
          {:light_video, title},
          "is closing",
          {:positive_score, "#{positives}"},
          "in favor that",
          username,
          "goes wild and gets gorged on folate, vitamin c and potassium",
          {:emoji, "🍅"},
          "."
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
          {:emoji, "💿"},
          "Dj",
          username,
          "just doesn't care and downvotes it's way out of the queue."
        ]
      ],
      2 => [
        [{:emoji, "💿"}, "Dj", username, {:emoji, "👎"}, {:light_video, title}, "."],
        [
          {:emoji, "💿"},
          "Dj",
          username,
          "takes a",
          {:emoji, "🍅"},
          "bath while the score tells",
          {:negative_score, "#{negatives}"},
          "against."
        ]
      ],
      3 => [
        [
          {:emoji, "💿"},
          "Dj",
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
    default = [username, "cheers", {:emoji, "🎉"}, "at", {:light_video, title}, "."]

    %{
      1 => [
        default,
        [username, "rapidly gets in the mix and upvotes", {:light_video, title}, "."]
      ],
      2 => [
        default,
        [
          "Spectator",
          username,
          "listened for a while and votes in favor. Seems to be enjoying",
          {:light_video, title},
          "."
        ]
      ],
      3 => [
        default,
        [
          "In the last minute",
          username,
          "slips out from the crown to cheer for",
          {:light_video, title},
          {:emoji, "🎉"},
          "and leaves the score",
          {:positive_score, "#{positives}"},
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
    default = [username, "cheers", {:emoji, "🎉"}, "at", {:light_video, title}, "."]

    %{
      1 => [
        default,
        [
          username,
          "shows",
          {:light_video, title},
          "some support but looks like the odds are against from the beginning. Score tells",
          {:negative_score, "#{negatives}"},
          "against and",
          {:positive_score, "#{positives}"},
          "in favor."
        ]
      ],
      2 => [
        default,
        [
          "Without a hint of shame",
          username,
          "cheers at",
          {:light_video, title},
          "despite the obvious boredom. Score tells",
          {:negative_score, "#{negatives}"},
          "against and",
          {:positive_score, "#{positives}"},
          "in favor."
        ]
      ],
      3 => [
        default,
        [
          username,
          "waited 'til the end to show some compasion.",
          {:light_video, title},
          "took a total of votes of",
          {:negative_score, "#{negatives}"},
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
    default = [username, "throws", {:emoji, "🍅"}, "at", {:light_video, title}, "."]

    %{
      1 => [
        default,
        [
          "Out of nowhere",
          username,
          "swiftly throws a",
          {:emoji, "🍅"},
          "over",
          {:light_video, title},
          "."
        ]
      ],
      2 => [
        default,
        [
          "Without a hint of shame",
          username,
          "throws a",
          {:emoji, "🍅"},
          "but it's not enough to overcome",
          {:positive_score, "#{positives}"},
          "in favor against",
          "#{negatives} for",
          {:light_video, title},
          "."
        ],
        [
          username,
          "waited halfway at",
          {:light_video, title},
          "and intimidates the Dj with a shiny",
          {:emoji, "🍅"},
          "Score is",
          {:positive_score, "#{positives}"},
          "in favor and",
          {:negative_score, "#{negatives}"},
          "against."
        ]
      ],
      3 => [
        default,
        [
          "Spectator",
          username,
          "throws a rotten",
          {:emoji, "🍅"},
          "that's been holding all this time! Still can't beat score of",
          {:positive_score, "#{positives}"},
          "in favor for",
          {:light_video, title},
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
    default = [username, "throws", {:emoji, "🍅"}, "at", {:light_video, title}, "."]

    %{
      1 => [
        default,
        [
          username,
          "quickly leaps into action and throws some fresh",
          {:emoji, "🍅"},
          "at",
          {:light_video, title},
          "to put the score down to",
          {:negative_score, "#{negatives}"},
          "against."
        ]
      ],
      2 => [
        default,
        [
          "Spectator",
          username,
          "tirelessly strikes with a dripping",
          {:emoji, "🍅"},
          "and leaves",
          {:light_video, title},
          "with",
          {:negative_score, "#{negatives}"},
          "votes against."
        ]
      ],
      3 => [
        default,
        [
          "Naughty",
          username,
          "takes the score down to",
          {:negative_score, "#{negatives}"},
          "by throwing a bag of decomposting",
          {:emoji, "🍅"},
          "at",
          {:light_video, title},
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
