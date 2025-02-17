-module(hstreamdb_erlang_example).

-export([bench/0, readme/0, consumer_test/0]).
-export([remove_all_streams/1]).

-define(ENABLE_PRINT, true).

% --------------------------------------------------------------------------------

remove_all_streams(Channel) ->
    {ok, Streams} = hstreamdb_erlang:list_streams(Channel),
    lists:foreach(
        fun(Stream) ->
            ok = hstreamdb_erlang:delete_stream(Channel, Stream, #{
                ignoreNonExist => true, force => true
            })
        end,
        lists:map(fun(Stream) -> maps:get(streamName, Stream) end, Streams)
    ).

flatten_duplicate(N, XS) ->
    XSS = lists:duplicate(N, XS),
    lists:flatten(XSS).

% --------------------------------------------------------------------------------

bench(Opts, Tid) ->
    SelfPid = self(),
    io:format("Opts: ~p~n", [Opts]),
    #{
        producerNum := ProducerNum,
        payloadSize := PayloadSize,
        keyNum := KeyNum,
        serverUrl := ServerUrl,
        replicationFactor := ReplicationFactor,
        backlogDuration := BacklogDuration,
        reportIntervalSeconds := ReportIntervalSeconds,
        batchSetting := BatchSetting,
        append_worker_num := AppendWorkerNum
    } =
        Opts,
    Payload = get_bytes(PayloadSize),
    #{record_count_limit := RecordCountLimit} = BatchSetting,
    TurnN = 5000,

    SuccessAppends = atomics:new(1, [{signed, false}]),
    FailedAppends = atomics:new(1, [{signed, false}]),
    SuccessAppendsAdd = fun(X) -> atomics:add(SuccessAppends, 1, X) end,
    FailedAppendsIncr = fun() -> atomics:add(FailedAppends, 1, 1) end,
    SuccessAppendsGet = fun() -> atomics:get(SuccessAppends, 1) end,
    FailedAppendsGet = fun() -> atomics:get(FailedAppends, 1) end,
    LastSuccessAppends = atomics:new(1, [{signed, false}]),
    LastFailedAppends = atomics:new(1, [{signed, false}]),
    LastSuccessAppendsPut = fun(X) -> atomics:put(LastSuccessAppends, 1, X) end,
    LastFailedAppendsPut = fun(X) -> atomics:put(LastFailedAppends, 1, X) end,
    LastSuccessAppendsGet = fun() -> atomics:get(LastSuccessAppends, 1) end,
    LastFailedAppendsGet = fun() -> atomics:get(LastFailedAppends, 1) end,

    ReportLoop =
        spawn(fun ReportLoopFn() ->
            LastSuccessAppendsPut(SuccessAppendsGet()),
            LastFailedAppendsPut(FailedAppendsGet()),
            timer:sleep(ReportIntervalSeconds * 1000),

            ReportSuccessAppends =
                (SuccessAppendsGet() - LastSuccessAppendsGet()) / ReportIntervalSeconds,
            ReportFailedAppends =
                (FailedAppendsGet() - LastFailedAppendsGet()) / ReportIntervalSeconds,
            ReportThroughput = ReportSuccessAppends * PayloadSize / 1024,

            [{success_appends, XS}] = ets:lookup(Tid, success_appends),
            ets:insert(Tid, {success_appends, [ReportSuccessAppends | XS]}),
            case ?ENABLE_PRINT of
                true ->
                    io:format(
                        "[BENCH]: SuccessAppends=~p, FailedAppends=~p, throughput=~p~n",
                        [ReportSuccessAppends, ReportFailedAppends, ReportThroughput]
                    )
            end,

            ReportLoopFn()
        end),

    RecvIncrLoop = spawn(
        fun RecvIncrLoopFn() ->
            receive
                {record_ids, RecordIds} ->
                    SuccessAppendsAdd(length(RecordIds)),
                    RecvIncrLoopFn()
            after 5 * 1000 ->
                exit(ReportLoop, finished),
                SelfPid ! finished,
                io:format("[BENCH]: report finished~n")
            end
        end
    ),

    {ok, Channel} = hstreamdb_erlang:start_client_channel(ServerUrl),
    Producers = lists:map(
        fun(X) ->
            StreamName =
                hstreamdb_erlang_utils:string_format(
                    "test_stream-~p-~p-~p",
                    [X, erlang:system_time(second), erlang:unique_integer()]
                ),
            ok =
                hstreamdb_erlang:create_stream(
                    Channel,
                    StreamName,
                    ReplicationFactor,
                    BacklogDuration
                ),
            ProducerOption = hstreamdb_erlang_producer:build_producer_option(
                ServerUrl, StreamName, RecvIncrLoop, AppendWorkerNum, BatchSetting
            ),
            ProducerStartArgs = hstreamdb_erlang_producer:build_start_args(ProducerOption),
            {ok, Producer} = hstreamdb_erlang_producer:start_link(ProducerStartArgs),
            Producer
        end,
        lists:seq(1, ProducerNum)
    ),

    Append = fun(Producer, Record) ->
        try
            hstreamdb_erlang_producer:append(Producer, Record)
        catch
            _:_ = E ->
                logger:error("yield error: ~p~n", [E]),
                FailedAppendsIncr()
        end
    end,

    RecordXS = lists:map(
        fun(IX) ->
            hstreamdb_erlang_producer:build_record(
                Payload,
                hstreamdb_erlang_utils:string_format("~p-~s", [IX, hstreamdb_erlang_utils:uid()])
            )
        end,
        lists:seq(1, KeyNum)
    ),

    lists:foreach(
        fun(Producer) ->
            spawn(fun() ->
                lists:foreach(
                    fun(Ix) ->
                        Record = lists:nth((Ix rem 3) + 1, RecordXS),
                        Append(Producer, Record)
                    end,
                    lists:seq(1, TurnN * RecordCountLimit)
                ),
                hstreamdb_erlang_producer:flush(Producer)
            end)
        end,
        Producers
    ),

    receive
        finished -> ok
    end.

bench() ->
    Fun = fun({ProducerNum, AppendWorkerNum}) ->
        build_bench_settings(
            ProducerNum,
            AppendWorkerNum,
            hstreamdb_erlang_producer:build_batch_setting({record_count_limit, 400})
        )
    end,

    Opts = flatten_duplicate(2, [
        Fun({ProducerNum, AppendWorkerNum})
     || ProducerNum <- [1, 4, 8, 12, 16],
        AppendWorkerNum <- [4, 8, 16, 24, 32]
    ]),

    lists:foreach(
        fun({X, I}) ->
            io:format("~n"),
            Tid = ets:new(
                list_to_atom(
                    hstreamdb_erlang_utils:string_format("HSTREAM_ETS-~p", [I])
                ),
                [
                    public
                ]
            ),
            ets:insert(Tid, {success_appends, []}),
            bench(X, Tid),
            [{success_appends, XS}] = ets:lookup(Tid, success_appends),
            [_, _ | YS] = lists:sort(XS),
            Avg = (lists:sum(YS) / length(YS)),
            ProducerNum = maps:get(producerNum, X),
            AppendWorkerNum = maps:get(append_worker_num, X),
            io:format("[OK]: ~p~n", [{ProducerNum, AppendWorkerNum, Avg}]),
            timer:sleep(15 * 1000)
        end,
        lists:zip(
            Opts, lists:seq(1, length(Opts))
        )
    ).

common_bench_settings() ->
    #{
        payloadSize => 1,
        % serverUrl => "http://192.168.0.216:6570",
        serverUrl => "http://127.0.0.1:6570",
        replicationFactor => 1,
        backlogDuration => 60 * 30,
        reportIntervalSeconds => 3,
        keyNum => 3
    }.

build_bench_settings(
    ProducerNum,
    AppendWorkerNum,
    BatchSetting
) ->
    M = common_bench_settings(),
    M#{
        producerNum => ProducerNum,
        batchSetting => BatchSetting,
        append_worker_num => AppendWorkerNum
    }.

% --------------------------------------------------------------------------------

bit_size_128() ->
    <<"___hstream.io___">>.

get_bytes(Size) ->
    get_bytes(Size, k).

get_bytes(Size, Unit) ->
    SizeBytes =
        case Unit of
            k ->
                Size * 1024
            % m ->
            %     Size * 1024 * 1024
        end,
    lists:foldl(
        fun(X, Acc) -> <<X/binary, Acc/binary>> end,
        <<"">>,
        lists:duplicate(round(SizeBytes / 128), bit_size_128())
    ).

% --------------------------------------------------------------------------------

consumer_test() ->
    ServerUrl = "http://127.0.0.1:6570",
    StreamName = hstreamdb_erlang_utils:string_format("~s-~p-~p", [
        "___v2_test___", erlang:unique_integer(), erlang:system_time()
    ]),
    BatchSetting = hstreamdb_erlang_producer:build_batch_setting({record_count_limit, 3}),

    {ok, Channel} = hstreamdb_erlang:start_client_channel(ServerUrl),
    _ = hstreamdb_erlang:delete_stream(Channel, StreamName, #{
        ignoreNonExist => true,
        force => true
    }),
    ReplicationFactor = 3,
    BacklogDuration = 60 * 30,
    ok = hstreamdb_erlang:create_stream(
        Channel, StreamName, ReplicationFactor, BacklogDuration
    ),

    StartArgs = #{
        producer_option => hstreamdb_erlang_producer:build_producer_option(
            ServerUrl, StreamName, self(), 16, BatchSetting
        )
    },
    {ok, Producer} = hstreamdb_erlang_producer:start_link(StartArgs),

    SubscriptionId = hstreamdb_erlang_utils:string_format("~s-~p-~p", [
        "___v2_test___", erlang:unique_integer(), erlang:system_time()
    ]),
    ConsumerName = hstreamdb_erlang_utils:string_format("~s-~p-~p", [
        "___v2_test___", erlang:unique_integer(), erlang:system_time()
    ]),

    ok = hstreamdb_erlang:create_subscription(Channel, SubscriptionId, StreamName),

    lists:foreach(
        fun(_) ->
            Record = hstreamdb_erlang_producer:build_record(
                <<"_", (erlang:integer_to_binary(erlang:unique_integer()))/binary, "_">>
            ),
            hstreamdb_erlang_producer:append(Producer, Record)
        end,
        lists:seq(1, 1000)
    ),

    SelfPid = self(),

    ConsumerFun = fun(
        ReceivedRecord, Ack
    ) ->
        io:format("~p~n", [ReceivedRecord]),
        ok = Ack(),
        SelfPid ! consumer_ok
    end,

    spawn(fun() ->
        hstreamdb_erlang_producer:flush(Producer),
        hstreamdb_erlang_consumer:start(
            ServerUrl, SubscriptionId, ConsumerName, ConsumerFun
        )
    end),

    lists:foreach(
        fun(_) ->
            receive
                consumer_ok -> ok
            after 2000 -> exit(-1)
            end
        end,
        lists:seq(1, 1000)
    ).

readme() ->
    % ServerUrl = "http://192.168.0.216:6570",
    ServerUrl = "http://127.0.0.1:6570",
    StreamName = hstreamdb_erlang_utils:string_format("~s-~p", [
        "___v2_test___", erlang:time()
    ]),
    BatchSetting = hstreamdb_erlang_producer:build_batch_setting({record_count_limit, 3}),

    {ok, Channel} = hstreamdb_erlang:start_client_channel(ServerUrl),
    _ = hstreamdb_erlang:delete_stream(Channel, StreamName, #{
        ignoreNonExist => true,
        force => true
    }),
    ReplicationFactor = 3,
    BacklogDuration = 60 * 30,
    ok = hstreamdb_erlang:create_stream(
        Channel, StreamName, ReplicationFactor, BacklogDuration
    ),
    _ = hstreamdb_erlang:stop_client_channel(Channel),

    StartArgs = #{
        producer_option => hstreamdb_erlang_producer:build_producer_option(
            ServerUrl, StreamName, self(), 16, BatchSetting
        )
    },
    {ok, Producer} = hstreamdb_erlang_producer:start_link(StartArgs),

    io:format("StartArgs: ~p~n", [StartArgs]),

    lists:foreach(
        fun(_) ->
            Record = hstreamdb_erlang_producer:build_record(<<"_">>),
            hstreamdb_erlang_producer:append(Producer, Record)
        end,
        lists:seq(1, 100)
    ),

    hstreamdb_erlang_producer:flush(Producer),

    LoopFun = fun Loop() ->
        receive
            {record_ids, RecordIds} ->
                io:format(
                    "RecordIds: ~p~n", [RecordIds]
                ),
                Loop()
        after 2 * 1000 -> ok
        end
    end,

    LoopFun(),

    ok.
