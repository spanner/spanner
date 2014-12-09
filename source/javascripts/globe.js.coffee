#= require lib/d3
#= require lib/d3-plugins/topojson
#= require lib/d3-plugins/d3.geo.projection.v0

τ = 2 * Math.PI
rad = Math.PI / 180
deg = 180

class Globe
  constructor: (elid) ->
    element = document.getElementById(elid.replace('#', ''))
    @_w = element.offsetWidth
    if @_w > 800
      @_a = 16 / 9
    else if @_w > 500
      @_a = 16 / 12
    else
      @_a = 1
    @_h = @_w / @_a
    @_h = window.innerHeight if @_h > window.innerHeight
    @_s = 0.0025  #lats per second
    @_l = 0       # start at meridian

    @_globe_scale = 0.8
    @_diameter = (Math.min @_w, @_h) * @_globe_scale
    @_radius = @_diameter / 2

    @_background_projection = @reverseNellHammer(@_a)
      .scale(@_radius * .9)
      .translate([@_w / 2, @_h / 2])
      .precision(.1)

    @_projection = d3.geo.orthographic()
      .clipAngle(90)
      .translate([@_w / 2, @_h / 2])
      .scale(@_radius)
      .rotate([0, 0, 0])
      
    @_reverse_projection = @reverseOrthographic()
      .clipAngle(90)
      .translate([@_w / 2, @_h / 2])
      .scale(@_radius)
      .rotate([-180, 0, 0])

    @_background_path = d3.geo.path()
      .projection(@_background_projection)

    @_path = d3.geo.path()
      .projection(@_projection)

    @_reverse_path = d3.geo.path()
      .projection(@_reverse_projection)

    @_svg = d3.select(elid).append("svg")
      .attr("width", @_w)
      .attr("height", @_h)

    defs = @_svg.append("defs")
    ocean_fill = defs.append("radialGradient")
      .attr("id", "ocean_fill")
      .attr("cx", "52%")
      .attr("cy", "48%")
    ocean_fill.append("stop").attr("offset", "5%").attr("stop-color", "#ffffff").attr('stop-opacity', "0.9")
    ocean_fill.append("stop").attr("offset", "85%").attr("stop-color", "#ffffff").attr('stop-opacity', "0.75")
    ocean_fill.append("stop").attr("offset", "100%").attr("stop-color", "#bdbdbd").attr('stop-opacity', "0.6")

    land_fill = defs.append("radialGradient")
      .attr("id", "land_fill")
      .attr("cx", "52%")
      .attr("cy", "48%")
    land_fill.append("stop").attr("offset", "5%").attr("stop-color", "#46594b").attr('stop-opacity', "0.45")
    land_fill.append("stop").attr("offset", "100%").attr("stop-color", "#46594b").attr('stop-opacity', "1.0")

    d3.json "/data/world.topojson", @displayCountries


  ## Build feature set and populate globe
  #
  displayCountries: (error, world) =>

    # prepare a set of projections and translators 
    # that will map data onto display values

    country_features = topojson.feature(world, world.objects.countries)

    @_background_country_elements = @_svg.append("path")
      .datum(country_features)
      .attr("data-code", (d) -> d.id)
      .attr("d", @_background_path)
      .attr("class","country background")

    @_reverse_country_elements = @_svg.append("path")
      .datum(country_features)
      .attr("d", @_reverse_path)
      .attr("class","country back")

    @_sea = @_svg.append("circle")
      .attr("cx", @_w / 2)
      .attr("cy", @_h / 2)
      .attr("r", @_radius)
      .style("fill", "url(#ocean_fill)")

    @_country_elements = @_svg.append("path")
      .datum(country_features)
      .attr("d", @_path)
      .attr("class","country front")
      .style("fill", "url(#land_fill)")

    # d3.json "/data/ip_lat_lngs.json", @displayLocations
    @_t = new Date().getTime()
    @spin()

  displayLocations: (error, points) =>
    points = points.slice 0, 500
    circles = points.map ({lat:lat,lng:lng}={}) ->
      d3.geo.circle().origin([lng,lat]).angle(1.0)()

    multi_circles =
      type: "MultiPolygon"
      coordinates: circles.map (poly) -> poly.coordinates

    @_locations = @_svg.append('path')
      .datum(multi_circles)
      .attr("class","location")
      .attr("d", @_path)

    @_t = new Date().getTime()
    @spin()

  spin: () =>
    requestAnimationFrame @spin
    now = new Date().getTime()
    delta = now - @_t
    if delta
      rate = 1000.0 / delta
      @_rates ?= []
      @_rates.push rate
      @_rates.shift() if @_rates.length > 10
      average = Math.round(@_rates.reduce((v, c) -> v + c) / 10.0)
      @_rate_report ?= document.getElementById('rate')
      @_rate_report.innerText = "#{average}fps"

    @_l += delta * @_s
    @_projection.rotate([@_l, 0, 0])
    @_background_projection.rotate([@_l-180, 0, 0])
    @_reverse_projection.rotate([@_l-180, 0, 0])
    @_country_elements?.attr("d", @_path)
    @_background_country_elements?.attr("d", @_background_path)
    @_reverse_country_elements.attr("d", @_reverse_path)
    @_locations?.attr("d", @_path)
    @_t = now

  reverseNellHammer: (aspect=2) ->
    d3.geo.projection (λ, φ)  ->
      λ *= -1
      [λ * (1 + Math.cos(φ)) / aspect, 2 * (φ - Math.tan(φ / 2))]
  
  reverseOrthographic: () ->
    d3.geo.projection (λ, φ) ->
      λ += Math.PI
      [Math.cos(φ) * Math.sin(λ), Math.sin(φ)]



window.globe = new Globe('#globe')
