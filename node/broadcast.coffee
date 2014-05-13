Baba = require "../../lib/main"
_ = require "underscore"
mitohMembers = new Baba.Script "mitoh"

lunch = ["和食", "洋食", "中華", "その他"]
mitohMembers.昼食何が良いですか {format: "list", list: lunch}, (result)->
  console.log "method name: #{result.task.key}"
  console.log "return value: #{result.value}"