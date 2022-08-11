-module(bench).

-export([main/0, cb/1]).

-define(PAYLOAD_RAW,
        <<"0iZ8RjgSniERr2ACTYfQW5ZwTEnvxow9IkAOwhvxFeVcIk0AgAwQQdHZYjxGAXb83qxM"
          "liSbzjTPQfu2XhBLGxlbUyVDiCeOw9NouP9nAiVZ1rxwl3xwbute0Uw12mzeIUykjE9h"
          "juYjtLmI2etH41qhhNQWDOf5QfMj6biykk1mfzbsLrkGXFxl5VDtghEr2yWpwZJh1NX1"
          "n0iVnNeBZvVMOJYUWyXufFOQGJQo4bcyirqzJWs5jI14Tp8ExgluNIqr8DMrt77u4kyy"
          "1zL0zsnTQkN6wcopuzJizn4a3EJzxOFSN6wQczE4Eh0Yy4oYRkXiOIT9yWDqGZwDpoO8"
          "WTw2K3VKMqUbjbOlJQn7hXhyPE2fbkvvgYxKVTP3dOzElcl06dQbFMPDIB9IkNS2OWdp"
          "PmkiaRoQsJzGqYgNI8KeBg3TRa2RuQA5Em4213VxBlPfp8adHSysNaaPlomb3fJvvfk2"
          "3wHYMOfeBpNenIH51GiTPlE3VVDFPIU8BRVaXOzyebZgZMiOASLL5W8Zw8aeTrJrLEa5"
          "mZ991Ug7HTbBgyVuJgsc2m0w0ZzqBjb6yOoP4P4qj2Cmi7jDTX0RnbN0bGDNfcvzj40O"
          "PMTz0QlX0J2s7Kskrodrb6BD4qyXWKOc14kdcXwdLj0lPl43bQ7Bof5cJXYiCfe5ZxOF"
          "Etr1TYfEj3GBqaWDaLS3uCrl8Pt4Yzp8zijld1BFHKtiG92uuecgG3vh9VJjTXWx2lEy"
          "OFLR7GA84HSU5w7JGxlP8HALoFSTAZflXgAJSW96Kp8FfQ4CE7BKQN9ktVbsIODx3OUz"
          "vexuwEBZDszkk8jnX9m12LzdX5HmRCbp5jrrhU7MDbdE91UKYl2l0ggkuKwWlIiMjcFJ"
          "f4B1IQJfuHcrkkS11uFrMfvJP5xwNGUfLV0v8L24z9HCVfHWe1HOrh6h8xhVqTfSc5D0"
          "A5piZ5r6IcZ0kphyx7AaBhgE2SNGHzclhXsZayODNJFPNT7yxZzohtiwx0wZeWSIkGTP"
          "6nVWM4PhSykvCxXqlxXeRGyYsDPQdLgt7q1TQVyK01ZczbYPkHKihIv6rgzBnwhwfkaf"
          "lWfBP1Eqi8pFGQWuZKzf94dwz3us2zwopjQ0aerpyiwBXi4fSiN4lQFTqVOpmDkHc387"
          "PHMU9j9p1oINT3hXNZtNOViHGgfpAPs65sHcyXXltZv8eQkuC8I47Jf5yGXfyFXE8Q3b"
          "GJpJgRKovAoF0jZtznkWOqMyYeFmxlu7v4WeNvqqzCRnW2jfJbYCyIuiiASZCOxJVsLr"
          "pvQHuVO9cz36WeF1Ho3sGvGsnCVySyq6PqAHaeXQv9k7aiM4E9H1BpuBooAHLB91gMLR"
          "kYWYDZoxD2MYKy2JwbsZLaoOahR9g8JpFtXcSzNwJCS5VnBv9tdRjI4DteUcZobbnxqT"
          "7JfbcHP4PEVVETrp2ORoZduUz0twgBwrwQpqzYVhmMIHors7AtGsaJf935xcFKzZWYIy"
          "D6LahYdWZ7gnkMhuTRCexrZBtjGVMuFRPbRTn8knVbcmx5JAvd3qjsRfyL6IsdRWw9XJ"
          "XFgyL6dINuTyA5TxbhQR5uJifMK6kjgSkS9cS1t4AKU8E1MwIkGronDZNsDjPoidSo14"
          "9SdM5dBCFyPz8nRHrA9dcnonkOem4A1kQvGd0zCy8OHGihXbmSbp8MH74gyqgNn9juz7"
          "Wcp5XQohcc3959mSeXzkZhYPfoUSM5NsdA14t0FD3Pe7rwv45136GTv8MpUwSfWpKOPZ"
          "NNjE4rXzmndoCs6n5Esps6cC4c5VAb1XhxucuKO1b6iSdaS0He5QQs606SVyDRhOhRqB"
          "hRIxLOpbMacy66Y0NyOyBzh8CEyAJTGi7FHmFHMVhaXOMesDsZsXroIMIJIPvqX7Z5v4"
          "tDo6nciUW5sUxjJ8FAes3PuXIx31CAIIZVqfT4fGyPgzVoBXvOHEBSXXiJNBiXkqPfPu"
          "A8tzW6LxJmREmfdGZ4ccArbL3xtgyUd2ogGzzU02jhe00kYxYquKSRRI0M7EQNKif6S8"
          "MXgF2Evg7zZbQvt0Pkcxp0yEnw04Gb9IEZqoL3EpBUgIWTELmaLA0CPTEc7GyTbyrsrj"
          "vVJo4mmOS89MQ0fvCzv4lkc2IzwZTbx5G04c3eI32v7VOJf9ks8mojIqadKECt8jUtoR"
          "HAbxjnDOWMaOS10wqxSBQdkENsIpIffFrjjGX3riBjrPPCOrM6SaUM8jRIDwFVDSNCh8"
          "RTOKZaffqSKyBnNhg7QXXIcXUNdULIXoENVrt0fM3H4GkUYYSX5mjFI7ggNuJJMualIm"
          "mjLMSVqqLjSboEFLjBjsE5F8ufcR61rBiZsmn9eyLd63yW0hfIP4twUT6oPIvfy2NLIx"
          "6CromDvR8DW8svhJqwArb2iqQgli8T92cMHo0c6CMh3wlr7BwVBUVok7bW8ccpTp2ou7"
          "muxiBqeinXjRVkfXTLuLqHygmVxIJY0yyjnvQeqIpoBR63A7Wq9IY7ZuLk1eSGGTb9Mo"
          "EazkvYDcmXkJW1fdGsGvBFihOClOHyegnQn9zjjAEX4ZAizWAYypL3vEcGf3VaO5TRod"
          "lTt5lR1TBWikSFAqbE0EYMbmjph9z6Qf5GllTpCho2rHyRAwApyg6FmfUYXduTjsfiRA"
          "KOSemmRw8pZHyzOUq5GSAVCS9TvrZQ6wPEnR2TLlckl2g26AAKCdcdpILGGGw6XBhdo0"
          "KVdBXhhTiDmQz7TiAuyxeI6N2ZoI25w5TiZV3u2AYRYlgvhkqLuRQUbCOn7pxEQ90Myk"
          "8sxJL6oIs4OfgcMBNK9zDCc21uZybAyNMJwYIE9OJb2Z6EeFtWLKspf3UARkCKwsR80s"
          "SprKYJPAC2YI0S0TnVIaNR2EMEtn2us0UwssOb6968pdN8iWgMAKA5McbVrk5pvyNHIM"
          "qVEUP5mUBpZ1HP9dDbea2W3CH1oN9pea8ARUcN7ZFu3tsUfaROnbNErGmqYD6UOkQXOD"
          "KJSZOUAwBBO3mvF7ra8p87n8tA9hJv1ek9wJ1PIQKvVvvNrXB4pjGniUNROyxHdNvRDX"
          "3YOdhcKnn5gOlsZTpS91K55hIVCQszXI6GmuGaOEG6mSJJoPUia7R6WQXKO3SFRsmCmr"
          "NKxG62LDfLjETRfCJnjISxEhKhoE9Bvp36cp5f1RvtY9ENGPJtaUEB98aqEWhWYRykPD"
          "23ce9B9DWlADCe8m84wjCIJboaSAx89CZDJtWycSCyHRCOmZmemUkBdCGRQT7OYSPpze"
          "EpaZ55PRKhqXpzvewT37qH6ClhzN2Obfu4Lg9n2bmguuXzcsiyBCvK3suEhxY0cqjSC1"
          "aGTIX008vgr2HsaoygQUNeZ51DmvGZENOxvq5GjPo65ueWtSiyC1MBwk6d2JNnxr9UWP"
          "i5sd2gW6G1QWbAga4FFYogOy1o9Nzbu2gM7ECxv4QlBoxMwPJkDpVGGL8vVgPX5Ko01x"
          "T1aMiSgVkVfISgyM68CX9m6DCJzLEGtXrk5UZ1YMgSxTGtIZ4kEUOtWFuJ4u4VWXvA3x"
          "DKxfBVehDQFVt5LwCxO3O31Lja5nM1Cc3DqIunaRmB8o4kQaO7xMyMCfWlIm6wDj33pw"
          "HG2E1aTDG72cSygvfFpLXoe82wdrvGsqZqJsd5YNimoZyZZsetLd9aUMiMYlmS1H7OM4"
          "v2utlq8AHegT3dax0r0SlfbKfH3Dimsc1v11Np2naZCcO0k9j1CFtDoHjYtI8U0GzEvI"
          "GoMX0siyo3LfOhFbrIcfaDVMPSlW70VBnOaiI7lABW4VXwS98nLq45G7t6o4lFS6kDRX"
          "4XQgHsEz2cNl53UxB9xxAVPQ8ezTFV3yfr6gzFA2Tc489obSPJpt9alUrYvZLhKjulZw"
          "dRjmTnpWQFh0wZHUu9Q9qGcPrNJCMupKC1hznuHt8jY2PYbWykouZ6NRlACqqWqMyouG"
          "lcNnyFdG6pP7LHMoUwzrIejs7nLqT4vNs9Gs208xbVtTDQ31qUPd5qct6S3DdWUU2JZe"
          "EWjDHIhajhPiwdfCgBSA9cWUYOBgERx0hvHim0KOTki7aogPca6bC65qeWfAqxzqZD1Q"
          "REyzplVFc7Y81D6E">>).

cb(_) ->
  ok.

main() ->
  _ = application:ensure_all_started(hstreamdb_erl),
  RPCOptions = #{pool_size => 8},
  ClientOptions = [{url, "http://127.0.0.1:6570"}, {rpc_options, RPCOptions}],
  {ok, Client} = hstreamdb:start_client(test_c, ClientOptions),
  ProducerOpts =
    [{stream, "stream_0"}, {callback, {?MODULE, cb}}, {max_records, 15}, {interval, 5000}],
  {ok, Producer} = hstreamdb:start_producer(Client, bench_producer, ProducerOpts),

  RandKeyFun =
    fun() ->
       lists:flatten(
         io_lib:format("ok~p", [rand:uniform(400)]))
    end,
  PayloadRaw = ?PAYLOAD_RAW,
  LoopFun =
    fun Loop() ->
          hstreamdb:append(Producer, RandKeyFun(), raw, PayloadRaw),
          Loop()
    end,
  LoopFun().
