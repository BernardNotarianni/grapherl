dashboard =
  _create : ->
    @_state = {}

  _init: ->
    @_init_ui()
    @_init_toolbar()
    @_toolbar_events()

    if !@options.granularity? then @options.granularity = graph_utils.granularity.sec
    console.log "inside _init dashboard", @options.data
    if @options.data?
      #for Metric, Clients in @options.data
      $.each @options.data, (Metric, Clients) =>
        console.log Clients
        $.each Clients, (Client, Data) =>
          @get_data_from_daemon(Metric, Client)
          delete @options.data[Metric][Client]
    else
      @options.data = {}


  _init_ui: ->
    Display = UI.graphDisplayC3("c3_display1", "chart")
    @element.append(Display)


  _init_toolbar : ->
    Toolbar = @element.find('nav')

    # remove display
    Toolbar.find("#delDisplay").on "click", =>
      @element.remove()

    # update current metric display list
    CurrDispMetric = Toolbar.find("#currentDispMetric")
    @element.on "display_update", (e) =>
      e.stopImmediatePropagation()
      CurrDispMetric.empty()
      $.each @options.data, (Metric, Clients) =>
        $.each Clients, (Client, Data) =>
          Id = graph_utils.generate_id()
          CurrDispMetric.append("""
            <li id="#{Id}" data-metric="#{Metric}" data-client="#{Client}">
              <a href="#">#{Metric}
               <span style="font-size: 12px; color:gray;">#{Client}</span>
              </a>
            </li> """)

      @_toolbar_events()

    # change chart type
    Toolbar.find("#chart_type li").on "click", (e) =>
      @transform_chart(e.currentTarget.id)

    # add daterangepicker 
    @inti_daterangepicker()

    @element.find("#saveDisplay").on "click", =>
      @saveDisplay()


    RangePicker = Toolbar.find("#range_picker")
    RangePicker.unbind("apply.daterangepicker")
    RangePicker.on "apply.daterangepicker", (e) =>
      StartDate  = RangePicker.data('daterangepicker').startDate.unix()
      EndDate    = RangePicker.data('daterangepicker').endDate.unix()
      console.log StartDate, EndDate
      @update_all_metrics()



    Toolbar.find("#addMetric").on "click", =>
      $.event.trigger('selectionStart')
      @toggle_add_button(true)
      return false


    # once the selection is complete add the selected client to @options.data
    # and get the data from chart daemon
    Toolbar.find("#selectionDone").on "click", =>
      $.event.trigger('selectionDone')
      MetricSideBar = UI.sideBar()
      Metrics       = MetricSideBar.sidebar("get_selected_metric")

      for Metric in Metrics
        Mname = Metric.metric_name
        Cname = Metric.client_name

        # if metric doesn't already exits then add it
        if @options.data[Mname]?
          if !@options.data[Mname][Cname]?
            # @options.data[Mname][Cname] = {data: []}
            @get_data_from_daemon(Mname, Cname)
        else
          # @options.data[Mname] = {}
          # @options.data[Mname][Cname] = {data: []}
          @get_data_from_daemon(Mname, Cname)

      @toggle_add_button(false)


    # toggle button if selcection is canceled
    $(document).on "selectionCancel", =>
      @toggle_add_button(false)


    # on change new data is fetched from server
    Toolbar.find("#granularity").find('li').on "click", (e) =>
      Id = e.currentTarget.id
      @options.granularity = Id
      console.log @options.granularity
      #TODO trigger event to change chart acc to granularity


    return @options.toolbar = Toolbar


  # toogle metric selection button
  toggle_add_button: (State = false) ->
    if State == false
      @options.toolbar.find("#selectionDone").hide()
      @options.toolbar.find("#addMetric").show()
    else
      @options.toolbar.find("#addMetric").hide()
      @options.toolbar.find("#selectionDone").show()


  _toolbar_events: ->
    Toolbar = @element.find('nav')

    # remove metric from display
    MetricList = @options.toolbar.find("#removeMetric")
    MetricList.find("li").unbind("click.remove")
    MetricList.find("li").on "click.remove", (e) =>
      Metric = MetricList.find("##{e.currentTarget.id}").attr('data-metric')
      Client = MetricList.find("##{e.currentTarget.id}").attr('data-client')
      @removeMetric(Metric, Client)
      delete @options.data[Metric][Client]
      @element.trigger("display_update")


    # triggered when data for metric has been received by chart daemon
    @element.on "metric_data", (e, Metric, Client, Data) =>
      e.stopImmediatePropagation()
      # TODO(cases to cover) incoming data might belong to a new Client
      # or just added to existing data

      if @options.data[Metric]?

        if @options.data[Metric][Client]?
          # for Key, Val of Data.metric_data
          #   if @options.data[Metric][Client].data[Key]?
          #     delete Data.metric_data[Key]
          @update_metric_data(Metric, Client, Data.metric_data)

        else
          @options.data[Metric][Client] = {data: Data.metric_data}
          @add_metric_data(Metric, Client, Data.metric_data)

      else
        @options.data[Metric] = {}
        @options.data[Metric][Client] = {data: Data.metric_data}
        @add_metric_data(Metric, Client, Data.metric_data)


      @element.trigger("display_update")
      #@add_metric_data(Metric, Client, Data.metric_data)
      #@render_chart()

    return false

 
  update_all_metrics: ->
    for Metric, Clients of @options.data
      for Client, Data of Clients
        @get_data_from_daemon(Metric, Client)


  # ping chart daemon to give data
  get_data_from_daemon: (Metric, Client) ->
    RangePicker = @options.toolbar.find("#range_picker")
    Start = RangePicker.data('daterangepicker').startDate.unix()
    End   = RangePicker.data('daterangepicker').endDate.unix()
    console.log "getting data range: ", Start, End
    $(document).chartDaemon("get_metric_data",
      @element, Metric, Client, [Start, End], @options.granularity)


  inti_daterangepicker: ->
    # taken from daterangepicker.com
    RangePicker = @element.find("#range_picker")
    #@element.find("#range_picker").daterangepicker({
    RangePicker.daterangepicker({
      parentEl: "#graphDiv",
      format: 'MM/DD/YYYY',
      startDate: moment().subtract(3, 'hours'),
      endDate: moment(),
      minDate: '01/01/2015',
      maxDate: '12/31/2015',
      #dateLimit: { days: 60 },
      showDropdowns: true,
      showWeekNumbers: true,
      timePicker: true,
      timePickerIncrement: 1,
      timePicker12Hour: true,
      ranges: {
        'Today': [moment(), moment()],
        'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
        'Last 7 Days': [moment().subtract(6, 'days'), moment()],
        'Last 30 Days': [moment().subtract(29, 'days'), moment()],
        'This Month': [moment().startOf('month'), moment().endOf('month')],
        'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
      },
      opens: 'right',
      drops: 'down',
      buttonClasses: ['btn', 'btn-sm'],
      applyClass: 'btn-primary',
      cancelClass: 'btn-default',
      separator: ' to ',
      locale: {
        applyLabel: 'Submit',
        cancelLabel: 'Cancel',
        fromLabel: 'From',
        toLabel: 'To',
        customRangeLabel: 'Custom',
        daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr','Sa'],
        monthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
        firstDay: 1
      }
    })      



# fetch and cache data from server for metric
chartDaemon = 
  _cache : {}

  _create: ->
    @_bind_events()

  _init : ->
    return false

  get_metric_data: (element, Metric, Client, Range, Granularity) ->
    Cache = @_lookup_cache(Metric, Client, Range, Granularity)

    if Cache == false
      [Start, End] = Range
      #1437245094
      Url = "/metric/data/" + Metric + "/" + Client + "/" + #"1437244814:1437244614/" + Granularity
        Start.toString() + ":" + End.toString() + "/" + Granularity
      $.ajax(
        method : "GET"
        url    : Url
        success: (data) ->
          element.trigger("metric_data", [Metric, Client, data])
      )

    return false

  _lookup_cache: (Metric, Client, Range, Granularity) ->
    return false

  _bind_events: ->
    $(document).on "metricData", (e, Data) ->
      @_cache[Data.metric] = Data.points

  



















## demo graph
create_test_graph = ->
  data =
    labels: ["January", "February", "March", "April", "May", "June", "July"],
    datasets: [
      {
        label: "Metric 1",
        fillColor: "rgba(220,220,220,0.2)",
        strokeColor: "rgba(220,220,220,1)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: [65, 59, 80, 81, 56, 55, 40]
      },
      {
          label: "Metric 2",
          fillColor: "rgba(151,187,205,0.2)",
          strokeColor: "rgba(151,187,205,1)",
          pointColor: "rgba(151,187,205,1)",
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: "rgba(151,187,205,1)",
          data: [28, 48, 40, 19, 86, 27, 90]
      }
    ]

  data2 =
    metric1 :
      client1:
        data : [
          {'2013-01-01': 300}, {'2013-01-02': 200}, {'2013-01-03': 100},
          {'2013-01-04': 400}, {'2013-01-05': 150}, {'2013-01-06': 250}]

    metric2 :
      client2:
        data : [{'2013-01-01': 130}, {'2013-01-02': 340}, {'2013-01-03': 200},
          {'2013-01-04': 500}, {'2013-01-05': 250}, {'2013-01-07': 350}]


  #ctx = $("#myChart").get(0).getContext("2d");
  #myNewChart = new Chart(ctx).Line(data, {});
  #$("#display").chartjs_chartify({data: data})
  #$("#c3Frame0").c3_chartify({data: data2})
  #$("#c3Frame0").chartify({data: data2})
  #$("#c3Frame1").chartify({data: data2})
  # $("#c3Frame1").chartjs_chartify({data: data2})


  return false

