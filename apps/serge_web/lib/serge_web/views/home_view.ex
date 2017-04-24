defmodule Serge.Web.HomeView do
  use Serge.Web, :view

  import Phoenix.HTML.SimplifiedHelpers.TimeAgoInWords,
    only: [distance_of_time_in_words_to_now: 1]
end
