path = require "path"
Baba = require path.resolve "../../lib/main"
async = require "async"
_ = require "underscore"
vc = new Baba.VC "masuilab"

members = new Baba.Script vc
week = ["月","火","水","木","金"]

MEMBER = 3

members.参加可能な日程を選んでください {broadcast: MEMBER}, (results)->
  workers = _.pluck results, "worker"
  b = []
  work = []
  for i in [0..workers.length-1]
    worker = workers[i]
    b.push (callback)=>
      a = []
      for day in week
        for i in [1..6]
          date = "#{day}曜#{i}限"
          worker.参加可能ですか {description: date}, (result)->
            a.push result.value
            if result.task.description is "金曜6限"
              callback null, a
  async.parallel b, (err, result)->
    len = result[0].length-1
    b = {}
    for i in [0..len]
      a = []
      for k in [0..result.length-1]
        a.push result[k][i]
      c = _.reject a, (bool)->  
        return bool is false
      b[list[i]] = c.length
    m = _.max b, (n)->
      return n.val
    if m[0].length >= MEMBER
      members.以下の日程から開催日時を選んでください {description: m}, (result)->
        process.exit()
    else
      funcs = []
      funcs.push (args)=>
        if args.length is 1
          i = 1
        for k in [0..MEMBER-1]
          if !m[i][k]
            members.get(k).以下の日程になりそうですが、調整できませんか {description: list[i]}
        callback i
      async.waterfall funcs, (result)->
        console.log result