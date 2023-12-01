ERL_V=$(erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell)
IEX_V=$(elixir --version | grep 'Elixir ' | sed 's/.* \([0-9\.]*\) .*/\1/')

if [ $ERL_V != 25.0 ]
then
    echo -e Erlang version has to be 25.0
    echo -e Current version: $ERL_V
    exit 1
fi

if [ $IEX_V != 1.15.4 ]
then
    echo -e Erlang version has to be 1.15.4
    echo -e Current version: $ERL_V
    exit 1
fi


echo -e "\e[1;5m######" Generating secret... "\e[0m"
export SECRET_KEY_BASE="$(openssl rand -hex 64)"
echo -e "\e[1;5m######" Done: $SECRET_KEY_BASE "\e[0m"

echo -e "\e[1;5m######" Setting env... "\e[0m"
export CXXFLAGS="-Wno-error=shadow -Wno-deprecated-copy -Wno-redundant-move
-Wno-pessimizing-move"
export MIX_ENV=prod
# export NODE_ENV=production
echo -e "\e[1;5m######" Done "\e[0m"

echo -e "\e[1;5m######" Configuring rebar and hex... "\e[0m"
mix local.rebar --force
mix local.hex --force
echo -e "\e[1;5m######" Done "\e[0m"
echo -e "\e[1;5m######" Getting deps.. "\e[0m"  .
mix deps.get || exit 2
echo -e "\e[1;5m######" Done "\e[0m"
echo -e "\e[1;5m######" Compiling repl... "\e[0m"
mix deps.compile || mix deps.compile || exit 2
echo -e "\e[1;5m######" Done "\e[0m"


echo -e "\e[1;5m######" Npm shit... "\e[0m"
cd assets
npm install || exit 2
npm run deploy || exit 2
node node_modules/webpack/bin/webpack.js --mode production || exit 2
cd ..

echo -e "\e[1;5m######" Done "\e[0m"

echo -e "\e[1;5m######" Phoenix digest... "\e[0m"
mix phx.digest
echo -e "\e[1;5m######" Done "\e[0m"

echo -e "\e[1;5m######" Making a release... "\e[0m"
mix release
echo -e "\e[1;5m######" Success. Now run the server with: "\e[0m"
echo -e "\e[1;5m######" _build/prod/rel/app/bin/app start "\e[0m"
