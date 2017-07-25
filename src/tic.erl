%%%-------------------------------------------------------------------
%%% @author Juan Jose Comellas <juanjo@comellas.org>
%%% @author Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>
%%% @author Paul Oliver <puzza007@gmail.com>
%%% @author Siraaj Khandkar <siraaj@khandkar.net>
%%% @author Michael Truog <mjtruog@gmail.com>
%%% @copyright (C) 2013 Ubiquiti Networks, Inc.
%%% @doc Functions that convert from and to common time formats.
%%% @end
%%%-------------------------------------------------------------------
-module(tic).

-export_type(
    [ epoch_microseconds/0
    , epoch_milliseconds/0
    , epoch_seconds/0
    , millisecond/0
    ]).

-export(
    [ datetime_to_epoch_msecs/1
    , datetime_plus_days/2
    , datetime_to_epoch_secs/1
    , datetime_to_iso8601/1
    , datetime_to_iso8601_usecs/0
    , epoch_msecs_to_datetime/1
    , epoch_msecs_to_iso8601/1
    , epoch_msecs_to_usecs/1
    , epoch_secs_to_datetime/1
    , epoch_secs_to_iso8601/1
    , epoch_usecs_to_msecs/1
    , gregorian_msecs_to_iso8601/1
    , gregorian_secs_to_iso8601/1
    , iso8601_to_datetime/1
    , iso8601_to_epoch_msecs/1
    , iso8601_to_epoch_secs/1
    , iso8601_to_gregorian_msecs/1
    , iso8601_to_gregorian_secs/1
    , now_to_epoch_msecs/0
    , now_to_epoch_secs/0
    , now_to_epoch_usecs/0
    , timestamp_to_epoch_msecs/1
    , timestamp_to_epoch_secs/1
    , timestamp_to_epoch_usecs/1
    ]).


-type epoch_seconds() ::
    non_neg_integer().

-type epoch_milliseconds() ::
    non_neg_integer().

-type epoch_microseconds() ::
    non_neg_integer().

-type millisecond() ::
    0..999.


%% Days between Jan 1, 0001 (beginning of the Gregorian calendar) and Jan 1,
%% 1970 (Unix epoch) in seconds.  62167219200 =
%% calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}}).
-define(GREGORIAN_SECONDS_TO_UNIX_EPOCH, 62167219200).


-spec datetime_to_epoch_msecs({calendar:datetime1970(), millisecond()} | calendar:datetime1970()) ->
    epoch_milliseconds().
datetime_to_epoch_msecs({{_,_,_},{_,_,_}} = DateTime) ->
    datetime_to_epoch_msecs({DateTime, 0});
datetime_to_epoch_msecs({Datetime, Msecs}) when Msecs >= 0, Msecs < 1000 ->
    Seconds = calendar:datetime_to_gregorian_seconds(Datetime),
    (Seconds - ?GREGORIAN_SECONDS_TO_UNIX_EPOCH) * 1000 + Msecs.

-spec datetime_to_epoch_secs(calendar:datetime1970()) ->
    epoch_seconds().
datetime_to_epoch_secs(Datetime) ->
    Seconds = calendar:datetime_to_gregorian_seconds(Datetime),
    Seconds - ?GREGORIAN_SECONDS_TO_UNIX_EPOCH.

%% @doc Convert a date and time in the format returned by
%%      calendar:universal_time/0 to a binary string in the ISO 8601 format
%%      (e.g.  "2012-02-15T14:39:15Z"; "2012-02-15T14:39:15.671Z").
-spec datetime_to_iso8601(Datetime) ->
    binary()
    when Datetime ::  calendar:datetime()
                   | {calendar:datetime(), millisecond()}
       .
datetime_to_iso8601({{_, _, _}, {_, _, _}}=Datetime) ->
    datetime_to_iso8601(Datetime, <<$Z>>);
datetime_to_iso8601({{{_, _, _}, {_, _, _}}=Datetime, Mil}) when Mil < 1000 ->
    Decimals = bstr:lpad(integer_to_binary(Mil), 3, $0),
    datetime_to_iso8601(Datetime, <<$., Decimals/binary, $Z>>).

-spec datetime_to_iso8601(calendar:datetime(), Suffix :: binary()) ->
    binary().
datetime_to_iso8601({{Year, Month, Day}, {Hour, Min, Sec}}, Suffix) ->
    ToBin = fun (I, Width) -> bstr:lpad(integer_to_binary(I), Width, $0) end,
    YYYY = ToBin(Year  , 4),
    MM   = ToBin(Month , 2),
    DD   = ToBin(Day   , 2),
    Hh   = ToBin(Hour  , 2),
    Mm   = ToBin(Min   , 2),
    Ss   = ToBin(Sec   , 2),
    << YYYY/binary
     , $-
     , MM/binary
     , $-
     , DD/binary
     , $T
     , Hh/binary
     , $:
     , Mm/binary
     , $:
     , Ss/binary
     , Suffix/binary
    >>.

-spec datetime_to_iso8601_usecs() ->
    binary().
datetime_to_iso8601_usecs() ->
    {_, _, Microseconds} = Now = os:timestamp(),
    { {Year, Month, Day}
    , {Hour, Minute, Second}
    } = calendar:now_to_universal_time(Now),
    erlang:iolist_to_binary(io_lib:format("~4..0b-~2..0b-~2..0bT"
                                          "~2..0b:~2..0b:~2..0b."
                                          "~6..0bZ",
                                          [Year, Month, Day,
                                           Hour, Minute, Second,
                                           Microseconds])).

-spec epoch_msecs_to_datetime(epoch_milliseconds()) ->
    {calendar:datetime1970(), millisecond()}.
epoch_msecs_to_datetime(EpochMsecs) ->
    Epoch = EpochMsecs div 1000,
    Msecs = EpochMsecs rem 1000,
    Seconds = ?GREGORIAN_SECONDS_TO_UNIX_EPOCH + Epoch,
    Datetime = calendar:gregorian_seconds_to_datetime(Seconds),
    {Datetime, Msecs}.

-spec epoch_msecs_to_iso8601(epoch_milliseconds()) ->
    binary().
epoch_msecs_to_iso8601(Milliseconds) ->
    Datetime = epoch_msecs_to_datetime(Milliseconds),
    datetime_to_iso8601(Datetime).

-spec epoch_msecs_to_usecs(epoch_milliseconds()) ->
    epoch_microseconds().
epoch_msecs_to_usecs(Milliseconds) when is_integer(Milliseconds) ->
    Milliseconds * 1000.

-spec epoch_secs_to_datetime(epoch_seconds()) ->
    calendar:datetime1970().
epoch_secs_to_datetime(Seconds) ->
    SecsGregToEpoch = ?GREGORIAN_SECONDS_TO_UNIX_EPOCH,
    calendar:gregorian_seconds_to_datetime(SecsGregToEpoch + Seconds).

-spec epoch_secs_to_iso8601(epoch_seconds()) ->
    binary().
epoch_secs_to_iso8601(Seconds) ->
    Datetime = epoch_secs_to_datetime(Seconds),
    datetime_to_iso8601(Datetime).

-spec epoch_usecs_to_msecs(epoch_microseconds()) ->
    epoch_milliseconds().
epoch_usecs_to_msecs(Microseconds) when is_integer(Microseconds) ->
    Microseconds div 1000.

-spec gregorian_msecs_to_iso8601(Time :: non_neg_integer()) ->
    binary().
gregorian_msecs_to_iso8601(Time) ->
    Secs = Time div 1000,
    Msecs = Time rem 1000,
    datetime_to_iso8601({calendar:gregorian_seconds_to_datetime(Secs), Msecs}).

-spec gregorian_secs_to_iso8601(Seconds :: non_neg_integer()) ->
    binary().
gregorian_secs_to_iso8601(Seconds) ->
    Datetime = calendar:gregorian_seconds_to_datetime(Seconds),
    datetime_to_iso8601(Datetime).

%% @doc Convert a datetime in the ISO 8601 format to a date and time in the
%%      format returned by calendar:universal_time/0.
-spec iso8601_to_datetime(binary()) ->
       calendar:datetime()
    | {calendar:datetime(), millisecond()}
    .
iso8601_to_datetime(
<< YYYY:4/binary , $- , MM:2/binary , $- , DD:2/binary
 , $T
 , Hh:2/binary   , $: , Mm:2/binary , $: , Ss:2/binary , Tail/binary>>
) ->
    Date =
        { binary_to_integer(YYYY)
        , binary_to_integer(MM)
        , binary_to_integer(DD)
        },
    Time =
        { binary_to_integer(Hh)
        , binary_to_integer(Mm)
        , binary_to_integer(Ss)
        },
    Datetime = {Date, Time},
    case Tail of
        <<"Z">> ->
            Datetime;
        <<".000Z">> ->
            Datetime;
        <<$., Millisec:3/binary, $Z>> ->
            {Datetime, binary_to_integer(Millisec)};
        <<$., Millisec:3/binary, UtcOffset:6/binary>> ->
            UTC = local_datetime_to_utc(Datetime, UtcOffset),
            {UTC, binary_to_integer(Millisec)};
        <<UtcOffset:6/binary>> ->
            local_datetime_to_utc(Datetime, UtcOffset)
    end.

-spec iso8601_to_epoch_msecs(binary()) ->
    epoch_milliseconds().
iso8601_to_epoch_msecs(Bin) ->
    Datetime = iso8601_to_datetime(Bin),
    datetime_to_epoch_msecs(Datetime).

-spec iso8601_to_epoch_secs(binary()) ->
    epoch_seconds().
iso8601_to_epoch_secs(Bin) ->
    Datetime = iso8601_to_datetime(Bin),
    datetime_to_epoch_secs(Datetime).

-spec iso8601_to_gregorian_msecs(binary()) ->
    Milliseconds :: non_neg_integer().
iso8601_to_gregorian_msecs(Bin) ->
    case iso8601_to_datetime(Bin) of
        {Datetime, Msecs} when is_integer(Msecs) ->
            calendar:datetime_to_gregorian_seconds(Datetime) * 1000 + Msecs;
        Datetime ->
            calendar:datetime_to_gregorian_seconds(Datetime) * 1000
    end.

-spec iso8601_to_gregorian_secs(binary()) ->
    Seconds :: non_neg_integer().
iso8601_to_gregorian_secs(Bin) ->
    Datetime =
        case iso8601_to_datetime(Bin) of
            {Datetime1, Millisecs} when is_integer(Millisecs) -> Datetime1;
            Datetime1                                         -> Datetime1
        end,
    calendar:datetime_to_gregorian_seconds(Datetime).

-spec local_datetime_to_utc(calendar:datetime(), UtcOffset :: binary()) ->
    calendar:datetime().
local_datetime_to_utc(LocalDatetime, UtcOffset) ->
    <<Sign, TimezoneHour:2/binary, $:, TimezoneMin:2/binary>> = UtcOffset,
    LocalSec = calendar:datetime_to_gregorian_seconds(LocalDatetime),
    %% Convert the the seconds in the local timezone to UTC.
    TimezoneMinInt  = binary_to_integer(TimezoneMin),
    TimezoneHourInt = binary_to_integer(TimezoneHour),
    Offset = ((TimezoneHourInt * 3600 + TimezoneMinInt) * 60),
    UtcSec =
        case Sign of
            $- -> LocalSec - Offset;
            $+ -> LocalSec + Offset
        end,
    calendar:gregorian_seconds_to_datetime(UtcSec).

-spec now_to_epoch_msecs() ->
    epoch_milliseconds().
now_to_epoch_msecs() ->
    Timestamp = os:timestamp(),
    timestamp_to_epoch_msecs(Timestamp).

-spec now_to_epoch_secs() ->
    epoch_seconds().
now_to_epoch_secs() ->
    Timestamp = os:timestamp(),
    timestamp_to_epoch_secs(Timestamp).

-spec now_to_epoch_usecs() ->
    epoch_microseconds().
now_to_epoch_usecs() ->
    Timestamp = os:timestamp(),
    timestamp_to_epoch_usecs(Timestamp).

-spec timestamp_to_epoch_msecs(erlang:timestamp()) ->
    epoch_milliseconds().
timestamp_to_epoch_msecs({Megasecs, Secs, Microsecs}) ->
    Megasecs * 1000000000 + Secs * 1000 + Microsecs div 1000.

-spec timestamp_to_epoch_secs(erlang:timestamp()) ->
    epoch_seconds().
timestamp_to_epoch_secs({Megasecs, Secs, _Microsecs}) ->
    Megasecs * 1000000 + Secs.

-spec timestamp_to_epoch_usecs(erlang:timestamp()) ->
    epoch_microseconds().
timestamp_to_epoch_usecs({Megasecs, Secs, Microsecs}) ->
    Megasecs * 1000000000000 + Secs * 1000000 + Microsecs.

-spec datetime_plus_days(calendar:datetime(), integer()) -> calendar:datetime().
datetime_plus_days({Date, Time}, N) ->
    GregDays = calendar:date_to_gregorian_days(Date),
    NextDay = calendar:gregorian_days_to_date(GregDays + N),
    {NextDay, Time}.
