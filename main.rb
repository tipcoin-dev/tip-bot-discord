require 'discordrb'
require 'coinrpc'
require 'bigdecimal'
require 'dotenv/load'
require 'pp'

VERSION = "1.0.0"
CONFIRM = ENV["CONF_CONFIRM"].to_i
FEE = ENV["CONF_FEE"].to_f
MINIMUM = "%.8f" % ENV["CONF_MINIMUM"]
WITHDRAWMINIMUM = ENV["CONF_WITHDRAWMINIMUM"].to_f
ADMIN = "268111717664423938"

tipClient = CoinRPC::Client.new(ENV["RPC_URL"])

bot = Discordrb::Commands::CommandBot.new(token: ENV["DISCORD_TOKEN"], client_id: ENV["DISCORD_CLIENT_ID"], prefix: ENV["DISCORD_PREFIX"])

# show information about tipcoin
bot.command(:info) do |event|  
  getblockchaininfo = tipClient.getblockchaininfo()
  getnetworkinfo = tipClient.getnetworkinfo()

  block = getblockchaininfo['blocks']
  hash_rate = tipClient.getnetworkhashps().to_f / 1000
  difficulty = getblockchaininfo['difficulty']
  connection = getnetworkinfo['connections']
  client_version = getnetworkinfo['subversion']
  blockchain_size = getblockchaininfo['size_on_disk'] / 1000000000

  event.channel.send_embed do |embed|
    embed.title = "Tipcoin info"
    embed.colour = 0x0043ff

    embed.add_field(name: "__Current block height__", value: "#{block}")

    embed.add_field(name: "__Network hash rate__", value: "#{hash_rate} KH/s")

    embed.add_field(name: "__Difficulty__", value: "#{difficulty}")

    embed.add_field(name: "__Connections__", value: "#{connection}")

    embed.add_field(name: "__Client Version__", value: "#{client_version}")

    embed.add_field(name: "__Block chain size__", value: "About #{blockchain_size} GB")

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
  end
end

# show help message
bot.command(:help) do |event|  
  event.channel.send_embed do |embed|
    embed.title = "TIP Bot Command List:"
    embed.colour = 0xa5af0d

    embed.add_field(name: "**//help**", value: "This is the command you have just used :wink:")

    embed.add_field(name: "**//info**", value: "Show Tipcoin Core wallet/blockchain info")

    embed.add_field(name: "**//balance**", value: "Show your Tipcoin balance")

    embed.add_field(name: "**//deposit**", value: "Show your Tipcoin deposit address")

    embed.add_field(name: "**//tip**", value: "Tip specified user [//tip @acidtib 1] to tip 1 Tipcoin \nyou can also attach a note to the tip, [//tip @acidtib 1 thank you]")

    embed.add_field(name: "**//withdraw**", value: "Withdraw Tipcoin from your wallet [//withdraw ADDRESS AMOUNT]")

    embed.add_field(name: "**//withdrawall**", value: "Withdraw all Tipcoin from your wallet. [//withdrawall ADDRESS]")

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
  end
end

# show user balance
bot.command(:balance) do |event|
  account = event.message.author.id.to_s

  balance = tipClient.getbalance(account, CONFIRM)
  unconfirmed = tipClient.getbalance(account, 0)

  unconfirmed_balance = unconfirmed - balance

  event.channel.send_embed do |embed|
    embed.title = "Your balance"
    embed.colour = 0x29e027

    embed.add_field(name: "Confirmed", value: "#{balance} TIP")

    embed.add_field(name: "Un-Confirmed", value: "#{unconfirmed_balance} TIP")

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
  end
end

# show user deposit address
bot.command(:deposit) do |event|
  account = event.message.author.id.to_s

  address = tipClient.getaccountaddress(account)

  event.channel.send_embed do |embed|
    embed.title = "**Your deposit address**"
    embed.colour = 0x29e027

    embed.add_field(name: "Deposit Tipcoin to this address", value: "click to enlarge the QR code")

    embed.add_field(name: "-------", value: address)

    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: "https://chart.googleapis.com/chart?cht=qr&chs=500x500&chl=#{address}")

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
  end
end

# tip specified user
bot.command(:tip, min_args: 2) do |event, mention, amount, *note|
  from = event.message.author.id.to_s

  puts "-"*30
  pp mention

  # what was mention, user or role
  # <@!268111717664423938> user
  # <@&854538384742678549> role

  if mention.include?("<@&") == true
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
              
      embed.add_field(name: "Make sure you tag @ a user in this server and not a role", value: ":sweat_smile:")
        
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return
  elsif mention.include?("<@") == false
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
              
      embed.add_field(name: "Make sure you tag @ a user in this server", value: ":sweat_smile:")
        
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return  
  else
    begin
      to = mention.gsub("<@", "").gsub(">", "").gsub("!", "")

      to_username = bot.user(to).username
    rescue => exception
      event.channel.send_embed do |embed|
        embed.title = "We have an issue"
        embed.colour = 0xd0021b
                
        embed.add_field(name: "Cant find username, make sure you tag @ a user in this server", value: ":sweat_smile:")
          
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
      end
      return
    end
  end

  amount = Float(amount, exception: false)
  amount = BigDecimal(amount.to_s)
  amount = "%.8f" % amount

  balance = tipClient.getbalance(from, CONFIRM)

  note = note.join(" ")

  # check for a valid amount
  if amount.to_f.is_a?(Float)
    # check length of discord user id is 18 or 17
    if to.length == 18 or to.length == 17
      # check if tip is going to self
      if from == to
        # You cannot tip to yourself
        event.channel.send_embed do |embed|
          embed.title = "We have an issue"
          embed.colour = 0xd0021b
          
          embed.add_field(name: "You cannot tip to yourself", value: ":thinking:")
    
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
        end
      
      # check if it's at least minimum
      elsif amount.to_f < MINIMUM.to_f
        event.channel.send_embed do |embed|
          embed.title = "We have an issue"
          embed.colour = 0xd0021b
      
          embed.add_field(name: "Amount must be at least #{MINIMUM} TIP", value: "#{amount} TIP")
      
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
        end

      # check if from account has available balance
      elsif amount.to_f > balance
        event.channel.send_embed do |embed|
          embed.title = "We have an issue"
          embed.colour = 0xd0021b
      
          embed.add_field(name: "You don't have enough balance", value: "Your balance #{balance} TIP")
      
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
        end

      else
        # attempt move of funds
        # tipcoin-cli move from to amount

        # check if tip is going to bot
        to_bot = (to == event.bot.profile.id.to_s)
        # assign the destination to the bot admin
        to = ADMIN if to_bot


        begin
          move_istrue = tipClient.move(from, to, amount)
        rescue => exception
          pp exception

          event.channel.send_embed do |embed|
            embed.title = "We have an issue"
            embed.colour = 0xd0021b
        
            embed.add_field(name: "Something Bad Happened", value: "go find help")
        
            embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
          end
        else
          if move_istrue
            event.channel.send_embed do |embed|
              embed.title = "TIP Action"
              embed.colour = 0x29e027
          
              embed.add_field(name: "@#{event.message.author.username} tipped @#{to_username}", value: "#{amount} TIP")

              if note.length != 0
                embed.add_field(name: "note:", value: note)
              end

              if to_bot
                embed.add_field(name: "Thank you for donating!", value: ":star_struck:")
              end
          
              embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
            end
          end
        end
      end

    else
      # invalid to user
      event.channel.send_embed do |embed|
        embed.title = "We have an issue"
        embed.colour = 0xd0021b
        
        embed.add_field(name: "Invalid User", value: mention)
  
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
      end
    end
  else
    # invalid amount
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
      
      embed.add_field(name: "Invalid Amount", value: amount)

      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
  end
end

# withdraw Tipcoin from user wallet
bot.command(:withdraw, min_args: 2, max_args: 2) do |event, address, amount|
  account = event.message.author.id.to_s

  amount = Float(amount, exception: false)
  amount = amount - FEE
  amount = BigDecimal(amount.to_s)
  amount = "%.8f" % amount

  address_validate = tipClient.validateaddress(address)

  balance = tipClient.getbalance(account, CONFIRM)

  if address_validate['isvalid'] == false
    # invalid address
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
      
      embed.add_field(name: "Invalid Address", value: address)

      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return
  
  elsif amount.to_f < WITHDRAWMINIMUM
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
  
      embed.add_field(name: "Withdraw amount must be at least #{WITHDRAWMINIMUM} TIP", value: "#{amount} TIP")
  
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return

  # check if user has available balance
  elsif amount.to_f > balance
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
  
      embed.add_field(name: "You don't have enough balance to withdraw #{amount} TIP", value: "Your balance #{balance} TIP")
  
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return
  
  else

    begin
      txid = tipClient.sendfrom(account, address, amount)
    rescue => exception
      pp exception

      event.channel.send_embed do |embed|
        embed.title = "We have an issue"
        embed.colour = 0xd0021b
    
        embed.add_field(name: "Something Bad Happened", value: "go find help")
    
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
      end
    else
      if txid.length == 64
        tx = tipClient.gettransaction(txid)

        tipClient.move(account, ADMIN, FEE)

        new_balance = tipClient.getbalance(account, CONFIRM)

        event.channel.send_embed do |embed|
          embed.title = "Withdrawal Complete"
          embed.colour = 0x29e027

          embed.add_field(name: "Block explorer", value: "https://explorer.tipcoin.us/tx/#{txid}")
      
          embed.add_field(name: "Withdraw #{amount} TIP", value: "withdraw fee is #{FEE} TIP \nPlease check the transaction at the above link")

          embed.add_field(name: "Your balance:", value: "#{new_balance} TIP")
      
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
        end
      end
    end

  end

end

# withdraw all Tipcoin from user wallet
bot.command(:withdrawall, min_args: 1, max_args: 1) do |event, address|
  account = event.message.author.id.to_s

  address_validate = tipClient.validateaddress(address)

  balance = tipClient.getbalance(account, CONFIRM)

  amount = balance - FEE

  if address_validate['isvalid'] == false
    # invalid address
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
      
      embed.add_field(name: "Invalid Address", value: address)

      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return
  
  elsif balance < WITHDRAWMINIMUM
    event.channel.send_embed do |embed|
      embed.title = "We have an issue"
      embed.colour = 0xd0021b
  
      embed.add_field(name: "Withdraw amount must be at least #{WITHDRAWMINIMUM} TIP", value: "Balance: #{balance} TIP")
  
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
    end
    return

  else

    begin
      txid = tipClient.sendfrom(account, address, amount)
    rescue => exception
      pp exception

      event.channel.send_embed do |embed|
        embed.title = "We have an issue"
        embed.colour = 0xd0021b
    
        embed.add_field(name: "Something Bad Happened", value: "go find help")
    
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
      end
    else
      if txid.length == 64
        tx = tipClient.gettransaction(txid)

        tipClient.move(account, ADMIN, FEE)

        new_balance = tipClient.getbalance(account, CONFIRM)

        event.channel.send_embed do |embed|
          embed.title = "Withdrawal Complete"
          embed.colour = 0x29e027

          embed.add_field(name: "Block explorer", value: "https://explorer.tipcoin.us/tx/#{txid}")
      
          embed.add_field(name: "Withdraw #{amount} TIP", value: "withdraw fee is #{FEE} TIP \nPlease check the transaction at the above link")

          embed.add_field(name: "Your balance:", value: "#{new_balance} TIP")
      
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "@#{event.message.author.username}", icon_url: event.message.author.avatar_url("png"))
        end
      end
    end

  end

end

bot.run