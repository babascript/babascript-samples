async = require "async"    
Baba = require "../../lib/main"
baba = new Baba.Script "masuilab"
phantom = require "phantom"
cheerio = require "cheerio"
querystring = require "querystring"
_ = require "underscore"
mm = require "methodmissing"

# 論文のサーベイを行うときの基準みたいなものを示す。
# こうすれば、まあ大丈夫。みたいな。

#キーワードを列挙する

class Acm

  url: "http://dl.acm.org/"
  papers: []

  constructor: ->
    
  search: (query, callback)->
    if !@ph 
      phantom.create (@ph)=>
        @ph.createPage (@page)=>
          @_search query, callback
    else
      @_search query, callback

  _search: (query, callback)->
    @page.open @url, (status)=>
      console.log "q is #{query}"
      @page.evaluate (q)->
        document.querySelector("input[type=text]").value = q
        document.querySelector("input[type=image]").click()
      , (r)=>
        setTimeout =>
          @page.evaluate ->
            list = {}
            i = 0 
            for p in document.getElementsByClassName "medium-text"
              list[i++] = {v: p.innerHTML, s: p.search}
            return list
          , (list)=>
            j = {}
            for key, value of list
              searchquery = value.s.replace "?", ""
              id = querystring.parse(searchquery).id
              j[id] = value.v
            callback j
        , 5000
      , query

  getPageFromCid: (cid, callback)->
    if !@ph
      phantom.create (@ph)=>
        @ph.createPage (@page)=>
          @_getPageFromCid cid, callback
    else
      @_getPageFromCid cid, callback

  _getPageFromCid: (q, callback)->
    @page.open "#{@url}citation.cfm?id=#{q}", (status)=>
      @page.includeJs 'http://code.jquery.com/jquery-1.9.1.min.js', ->
        console.log "cid is #{q}"
        callback()

  getAbstract: (cid, callback)->
    @getPageFromCid cid, ()=>
      @page.evaluate ->
        title = document.querySelector("h1 strong").innerHTML
        p = document.querySelector("#abstract p").innerHTML
        return {title, p}
      , callback

  getReferences: (cid, callback)->
    @getPageFromCid cid+"&preflayout=flat", ()=>
      @page.evaluate =>
        console.log "hoge"
        table = $("#fback div.flatbody:eq(2)").find("table a")
      , =>
        setTimeout =>
          @page.render "hoge.png"
          test()
        , 5000
      test = ()=>
        @page.evaluate ->
          list = []
          table = $("#fback div.flatbody:eq(2)").find("table a")
          table.each ->
            if $(@).attr("href").match /citation.cfm/ 
              url = $(@).attr "href"
              title = $(@).html().replace(/\t|\n/g, "")
              list.push
                title: title
                href: $(@).attr "href"
          return list
        , (list)=>
          for p in list
            q = p.href.replace "citation.cfm?", ""
            qq = querystring.parse(q)
            cid = qq.id
            p.cid = cid
          callback list
    
  addPaper: (cid)->
    papers.add "#{url}citation.cfm?id=#{cid}"

class SurveyMan

  papers: []
  checkedPapers: []
  org: null

  constructor: (type)->
    @man = new Baba.Script "masuilab"
    if type is "acm"
      @org = new Acm()
    else
      @org = new Acm()
    return mm @, (key, args)=>
      @man.methodmissing key, args

  startSurvey: =>
    @search()

  # キーワード選択→検索結果表示
  search: ->
    @man.探したい分野のキーワードを入力してください {format: "string"}, (result)=>
      @org.search result.value, (searchResult)=>
        console.log searchResult
        for k, v of searchResult
          @papers.push {type: "search", title: v, id: k}
        console.log @papers
        @selectPaper()

  selectPaper: =>
    console.log @papers
    l = []
    for k, v of @papers
      l.push v.title
    @man.関連しそうな論文を選択してください {format: "list", list: l}, (result)=>
      paper = _.find @papers, (v, k)=>
        return _.unescape(v.title) is _.unescape(result.value)
      @checkRelated paper.id

  checkRelated: (id)=>
    @org.getAbstract id, (data)=>
      if data is null
        @man.アブストラクトがなかったので論文選択しなおしてください ()=>
          @selectPaper()
        return
      title = data.title
      p = data.p
      @man.関連してますか {description: "#{title}: #{p}"}, (result)=>
        if result.value is true
          @checkedPapers.push {title: title, id: id}
          @getAbstract id, data

  getAbstract: (id, data)=>
    @man.要約してください {format: "string", description: "#{data.title}: #{data.p}" }, (result)=>
      bodyOfAbstract = result.value
      @man.参考文献から資料を探しますか (result)=>
        if result.value is true
          @org.getReferences id, (list)=>
            for k, v of list
              @papers.push {type: "references", title: v.title, id: v.id}
            @selectPaper()
        else
          @next()
  

  selectReference: (list)=>
    @man.参考文献から資料を探しますか (result)=>
      if result.value is true
        @selectPaper 
      else
        @next()

  next: =>
    @man.論文調査を続けますか (result)=>
      if result.value is true
        @selectPaper
      else
        console.log "ehnd"


selectPaper = (list)->
  l = []
  for key, value of list
    l.push value
  baba.こんな論文があります {format: "list", list: l}, (result)->
    id = ""
    for key, value of list
      if value is result.value
        id = key
    acm.getAbstract id, (data)->
      baba.アブストラクトですが関係してそうですか {format: "boolean", description: "#{data.title}: #{data.p}" }, (result)->
        if result.value is true
          acm.addPaper id
          baba.アブストラクトを要約してください {format: "string", description: "#{data.title}: #{data.p}" }, (result)->
            bodyOfAbstract = result.value
            # pdf のデータを取得する
            baba.参考文献から資料を探しますか (result)->
              if result.value is true
                acm.getReferences id, (list)->
                  console.log list
              else
                baba.論文検索続けますか (result)->
                  if result.value is true
                    selectPaper list
                  else
                    console.log acm.papers
        else
          baba.論文検索続けますか (result)->
            if result.value is true
              selectPaper list
            else
              console.log acm.papers


man = new SurveyMan("masuilab")
man.startSurvey()