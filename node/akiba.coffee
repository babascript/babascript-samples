Baba = require "../../lib/main"

a = new Baba.Script "player"
b = new Baba.Script "watcher"

a.秋葉原でかわいい女の子の写真をとれ {format: "image", broadcast: "all"}, (result)->
  worker = result.worker
  b.かわいいか判断してください {format: "boolean", image: result.value}, (result)->
    p = worker.get("point")
    if result.value is true then p++ else p--
    worker.set "point", p