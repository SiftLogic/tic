%%%-------------------------------------------------------------------
%%% @author Juan Jose Comellas <juanjo@comellas.org>
%%% @author Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>
%%% @author Paul Oliver <puzza007@gmail.com>
%%% @author Siraaj Khandkar <siraaj@khandkar.net>
%%% @copyright (C) 2013 Ubiquiti Networks, Inc.
%%% @end
%%%-------------------------------------------------------------------
-module(tic_SUITE).

%% CT callbacks
-export(
    [ all/0
    , groups/0
    , suite/0
    ]).

%% Tests
-export(
    [ t_datetime_to_epoch_test/1
    , t_datetime_to_iso8601_test/1
    , t_datetime_plus_day/1
    , t_epoch_to_datetime_test/1
    , t_epoch_to_iso8601_test/1
    , t_gregorian_seconds_to_iso8601_test/1
    , t_iso8601_to_datetime_test/1
    , t_iso8601_to_epoch_test/1
    , t_iso8601_to_gregorian_seconds_test/1
    , t_timestamp_to_epoch_test/1
    ]).


%% Days between Jan 1, 0001 (beginning of the Gregorian calendar) and Jan 1,
%% 1970 (Unix epoch) in seconds.  62167219200 =
%% calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}}).
-define(SECONDS_TO_UNIX_EPOCH, 62167219200).


suite() ->
    [{ct_hooks, [cth_surefire]}, {timetrap, {seconds, 120}}].

groups() ->
    Group = tic,
    Tests =
        [ t_datetime_to_epoch_test
        , t_datetime_to_iso8601_test
        , t_datetime_plus_day
        , t_epoch_to_datetime_test
        , t_epoch_to_iso8601_test
        , t_gregorian_seconds_to_iso8601_test
        , t_iso8601_to_datetime_test
        , t_iso8601_to_epoch_test
        , t_iso8601_to_gregorian_seconds_test
        , t_timestamp_to_epoch_test
        ],
    Options = [parallel],
    [{Group, Options, Tests}].

all() ->
    [{group, tic}].


t_datetime_to_iso8601_test(_) ->
    <<"2012-05-19T22:34:55Z">> =
        tic:datetime_to_iso8601({{2012,5,19},{22,34,55}}),
    <<"2012-11-30T09:01:00.486Z">> =
        tic:datetime_to_iso8601({{{2012,11,30},{9,1,0}},486}).

t_iso8601_to_datetime_test(_) ->
    {{2012,05,19},{22,34,55}} =
        tic:iso8601_to_datetime(<<"2012-05-19T22:34:55Z">>),
    {{{2012,11,30},{9,1,0}},486} =
        tic:iso8601_to_datetime(<<"2012-11-30T09:01:00.486Z">>),
    {{2018,12,06},{20,0,0}} =
        tic:iso8601_to_datetime(<<"2018-12-07T00:00:00-04:00">>).

t_gregorian_seconds_to_iso8601_test(_) ->
    GregorianSec =
        calendar:datetime_to_gregorian_seconds({{2012,10,5},{1,10,11}}),
    <<"2012-10-05T01:10:11Z">> =
        tic:gregorian_secs_to_iso8601(GregorianSec).

t_iso8601_to_gregorian_seconds_test(_) ->
    GregorianSec =
        calendar:datetime_to_gregorian_seconds({{1950,2,22},{15,30,14}}),
    GregorianSec =
        tic:iso8601_to_gregorian_secs(<<"1950-02-22T15:30:14Z">>),
    Ms = GregorianSec * 1000 + 653,
    Ms = tic:iso8601_to_gregorian_msecs(<<"1950-02-22T15:30:14.653Z">>).

t_datetime_to_epoch_test(_) ->
    Datetime = {{2000,1,1},{10,20,30}},
    GregEpochDiff = ?SECONDS_TO_UNIX_EPOCH,
    Epoch = calendar:datetime_to_gregorian_seconds(Datetime) - GregEpochDiff,
    Epoch = tic:datetime_to_epoch_secs(Datetime).

t_epoch_to_datetime_test(_) ->
    Datetime = {{2000,1,1},{10,20,30}},
    GregEpochDiff = ?SECONDS_TO_UNIX_EPOCH,
    Epoch = calendar:datetime_to_gregorian_seconds(Datetime) - GregEpochDiff,
    Datetime = tic:epoch_secs_to_datetime(Epoch).

t_epoch_to_iso8601_test(_) ->
    GregEpochDiff = ?SECONDS_TO_UNIX_EPOCH,
    Datetime = {{2011, 12, 31},{5,25,53}},
    Epoch = calendar:datetime_to_gregorian_seconds(Datetime) - GregEpochDiff,
    <<"2011-12-31T05:25:53Z">> = tic:epoch_secs_to_iso8601(Epoch),
    EpochMsecs = Epoch * 1000 + 672,
    ISO8601 = tic:epoch_msecs_to_iso8601(EpochMsecs),
    <<"2011-12-31T05:25:53.672Z">> = ISO8601.

t_iso8601_to_epoch_test(_) ->
    GregEpochDiff = ?SECONDS_TO_UNIX_EPOCH,
    Datetime = {{1989, 7, 20},{20,30,21}},
    GregSecs = calendar:datetime_to_gregorian_seconds(Datetime),
    Epoch = GregSecs - GregEpochDiff,
    Epoch = tic:iso8601_to_epoch_secs(<<"1989-07-20T20:30:21Z">>),
    Ms = Epoch * 1000 + 217,
    Ms = tic:iso8601_to_epoch_msecs(<<"1989-07-20T20:30:21.217Z">>).

t_timestamp_to_epoch_test(_) ->
    GregEpochDiff = ?SECONDS_TO_UNIX_EPOCH,
    Timestamp = os:timestamp(),
    Secs  = tic:timestamp_to_epoch_secs(Timestamp),
    Msecs = tic:timestamp_to_epoch_msecs(Timestamp),
    Usecs = tic:timestamp_to_epoch_usecs(Timestamp),
    Secs = Msecs div 1000,
    Msecs = Usecs div 1000,
    Secs = Usecs div 1000000,
    UnivTime = calendar:now_to_universal_time(Timestamp),
    GregSecs = calendar:datetime_to_gregorian_seconds(UnivTime),
    Secs = GregSecs - GregEpochDiff.

t_datetime_plus_day(_) ->
    Date = {{2014,10,3},{14,39,58}},
    NextDate = {{2014,10,4},{14,39,58}},
    NextDate = tic:datetime_plus_days(Date, 1).
