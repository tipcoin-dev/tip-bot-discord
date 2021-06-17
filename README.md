Tipcoin Discord Bot
====

A discord Tip-bot for Tipcoin

## Usage

Command prefix : `//`

|Command                         |Description                                  |Example                                            |
|--------------------------------|---------------------------------------------|---------------------------------------------------|
|`//info`                        |Show information of Tipcoin.                 |                                                   |
|`//help`                        |Show help message.                           |                                                   |
|`//balance`                     |Show your balance.                           |                                                   |
|`//deposit`                     |Show your deposit address.                   |                                                   |
|`//tip (@mention) (amount)`     |Tip specified amount to specified user.      |`//tip @acidtib 420`                               |
|`//withdraw (address) (amount)` |Send specified amount to specified address.  |`//withdraw TpCZwFjbEYAKCh8za2fuPd9btCfMA9EzsF 10` |
|`//withdrawall (address)`       |Send your all balance to specified address. |`//withdrawall TpCZwFjbEYAKCh8za2fuPd9btCfMA9EzsF`  |

### Tips

withdraw-fee is 0.001 TIP.

Number of Confirmations is 6 blocks.

Address type is `segwit`.

In `withdraw`, amount must be at least 0.5 TIP.

You can donate by Tipcoin to the bot. (example : /tip @TIP 3.939)

The address changes with each deposit, but you can use the previous one. However, it is recommended to use the latest address.

## Requirement

* Ruby
* Tipcoin Core

```
bundle install
```

## How to run

1. copy .env-example
```
cp .env-example .env
```

2. Edit configuration file of tipcoind (tipcoin.conf)

```
rpcuser=username
rpcpassword=password

rpcbind=127.0.0.1
rpcallowip=127.0.0.1

server=1
daemon=1
listen=1

deprecatedrpc=accounts
```

3. Run `tip-bot-discord`

```
bundle exec ruby main.rb
```