"use strict";



jQuery( document ).ready(function($) {


// OIPA URL - TODO - make dynamic

var oipaApiUrl = "https://dc-dfid.oipa.nl/api/";



// variables for the visualisation

var svg;

var margin = { top: 0, right: 0, bottom: 0, left: 0 },

    width = 600 - margin.right - margin.left,

    height = 20000 - margin.top - margin.bottom,

    nodeWidth = 20,

    nodeHeight = 20;



var colors = [d3.rgb(0, 130, 112), d3.rgb(58, 186, 168), d3.rgb(233, 186, 130), d3.rgb(59, 101, 126), d3.rgb(177, 68, 76), d3.rgb(0, 94, 165), d3.rgb(48, 48, 48), d3.rgb(48, 48, 48), d3.rgb(48, 48, 48), d3.rgb(48, 48, 48), d3.rgb(48, 48, 48), d3.rgb(48, 48, 48)];



var first = 1;



// this defined the height difference per tier

var y = d3.scale.ordinal().domain(d3.range(10)).rangePoints([0, 150 * 10], 1);



var Chain = function Chain(activityId) {

  this._activityId = activityId;



  this.chainId = null;

  this.links = null;

  this.activities = null;



  this.errors = null;

  this.chainCreated = false;



  this.graph = null;

  this.getChain();

};



Chain.prototype.getChain = function () {

  var that = this;



//  $.getJSON(oipaApiUrl + "chains/?format=json&includes_activity=" + this._activityId, function (data) {
    $.getJSON("/getChains?project=" + this._activityId, function (data) {

    // TODO - if there are no results then this will crash the script
    console.log(data.output);
    that.chainId = data.output.results[0].id;



    that.getLinks();

    that.getActivities();

  });

};



Chain.prototype.getLinks = function () {

  var that = this;



  //$.getJSON(oipaApiUrl + "chains/" + that.chainId + "/links/?format=json", function (data) {
  $.getJSON("/getLinks?chainId="+that.chainId, function (data) {
    // console.log(data)

    that.links = data.output;

    that.loadChainWhenReady();

  });

};



Chain.prototype.getActivities = function () {

  var that = this;


 
  //$.getJSON(oipaApiUrl + "chains/" + that.chainId + "/activities/?format=json&page_size=400&fields=iati_identifier,title,reporting_organisation", function (data) {
    $.getJSON("/getActivities?chainId="+that.chainId, function (data) {


    var activities = {};



    data.output.results.forEach(function (activity) {

      activities[activity.iati_identifier] = activity;

    });



    that.activities = activities;

    that.loadChainWhenReady();

  });

};



Chain.prototype.loadChainWhenReady = function () {

  if (this.activities != null && this.links != null & !this.chainCreated) {

    this.createChain();

    this.chainCreated = true;

  }

};



// from here on down, its pretty much d3 scripting

Chain.prototype.createChain = function () {

  // console.log('time to create the chain')



  // SET THE DATA UP



  // create d3 visualisation



  // the visualisation is based upon https://stackoverflow.com/questions/21598092/d3-force-layout-with-fixed-y-ranges-reducing-link-overlap



  var activities = this.activities;



  var nodesObj = {};



  // for each link, check if the start node and end node are in nodesObj. If not add them.

  this.links.forEach(function (link) {



    if (!nodesObj[link.start_node.activity_iati_id]) {



      nodesObj[link.start_node.activity_iati_id] = {

        _id: link.start_node.activity_iati_id,

        level: link.start_node.tier,

        bol: link.start_node.bol,

        eol: link.start_node.eol,

        activity: activities[link.start_node.activity_oipa_id]

      };

    }



    if (!nodesObj[link.end_node.activity_iati_id]) {



      nodesObj[link.end_node.activity_iati_id] = {

        _id: link.end_node.activity_iati_id,

        level: link.end_node.tier,

        bol: link.end_node.bol,

        eol: link.end_node.eol,

        activity: activities[link.end_node.activity_oipa_id]

      };

    }

  });



  var nodes = _.values(nodesObj);



  // enrich links with indexes of nodes

  this.links.forEach(function (link) {

    link.id = 'n' + link.id;

    link.source = _.findIndex(nodes, function (o) {

      return o._id === link.start_node.activity_iati_id;

    });

    link.target = _.findIndex(nodes, function (o) {

      return o._id === link.end_node.activity_iati_id;

    });

  });



  var graph = {

    nodes: nodes,

    links: this.links

  };



  this.graph = graph;



  var maxLevel = d3.max(nodes, function (d) {

    return d.level;

  });



  width = 1000 + nodes.length * 5;

  height = 200 * maxLevel;



  // USE D3 TO VISUALISE THE DATA

var svgScale = Math.min(300/2000,300/200);

  // create the base for the visualisation
console.log(svgScale);
  svg = d3.select("#chain-visualisation").append("svg").attr("width", width).attr("height", height)
  //.attr("transform", "translate(-100) scale(" + svgScale + ")")
  .call(d3.behavior.zoom().on("zoom", function () {
        //svg.attr("transform", "translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")")
        svg.attr("transform", "translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")")
      })).append("g").attr('id','spe');
  //svg.append('<g id="sp"></g>');

//svg.append('g').attr('id','spe');
//var root = d3.select('#chain-visualisation svg')

//zoomFit(0.95, 200, root);
//////////////////////////////////////////////////////
var root = svg.select('#spe');
var bounds = root.node().getBBox();
  // var parent = root.node().parentElement;
  // var fullWidth = parent.clientWidth,
  //     fullHeight = parent.clientHeight;
  // var width = bounds.width,
  //     height = bounds.height;
  // var midX = bounds.x + width / 2,
  //     midY = bounds.y + height / 2;
  // if (width == 0 || height == 0) return; // nothing to fit
  // var scale = (0.95 || 0.75) / Math.max(width / fullWidth, height / fullHeight);
  // var translate = [fullWidth / 2 - scale * midX, fullHeight / 2 - scale * midY];

  //console.trace("zoomFit", translate, scale);
  // root
  //   .transition()
  //   .duration(500 || 0) // milliseconds
  //   .call(zoom.translate(translate).scale(scale).event);
/////////////////////////////////////////////////////

  var intArray = [];

  for (var i = 0; i < maxLevel + 1; i++) {

    intArray.push(i);

  }

  // create the legend

  var legenNode = svg.selectAll(".legend-node").data(intArray).enter().append("g");



  legenNode.append("rect").attr("class", "legend-node").attr("x", 20).attr("y", function (d) {

    return d * 24 + 20;

  }).attr("width", nodeWidth).attr("height", nodeHeight).style("fill", function (d, i) {

    return colors[d];

  }).style("stroke", function (d, i) {

    return colors[d].darker(2);

  });



  legenNode.append("text").attr("x", 42).attr("y", function (d) {

    return d * 24 + 32;

  }).attr("fill", "black").text(function (d) {

    return "tier " + d;

  });



  // create the links

  var link = svg.selectAll(".link").data(graph.links).enter().append("line").attr("class", "link").style("stroke-width", 2).style("stroke", "#999");

  // .on("click", clickLink())

  // .on("mouseenter", mouseOverLink())

  // .on("mouseout", mouseOutLink);



  // create the nodes

  var node = svg.selectAll(".node").data(graph.nodes).enter().append("rect").attr("class", "node").attr("x", function (d) {

    return d.x;

  }).attr("y", function (d) {

    return d.y;

  }).attr("width", nodeWidth).attr("height", nodeHeight).style("fill", function (d, i) {

    return colors[d.level];

  }).style("stroke", function (d, i) {

    return colors[d.level].darker(2);

  });

  // .on("click", clickNode())

  // .on("mouseenter", mouseOverNode());



  // use the d3 force layout to animate the data and put it into the hierarchies

  var force = d3.layout.force().charge(-1000).gravity(0.2).linkDistance(20).size([width, height]);



  force.nodes(graph.nodes).links(graph.links).on("tick", tick).start();



  var that = this;

  setTimeout(function () {

    first = 0;

    force.start();

  }, 1000);



  function tick(e) {



    var k = first ? e.alpha : 5 * e.alpha;



    graph.nodes.forEach(function (o, i) {

      o.y += (y(o.level) - o.y) * k;

    });



    node.attr("x", function (d) {

      return d.x;

    }).attr("y", function (d) {

      return d.y;

    });



    link.attr("x1", function (d) {

      return d.source.x + nodeWidth / 2;

    }).attr("y1", function (d) {

      return d.source.y + nodeHeight / 2;

    }).attr("x2", function (d) {

      return d.target.x + nodeWidth / 2;

    }).attr("y2", function (d) {

      return d.target.y + nodeHeight / 2;

    });

  }



  // when loading, show th graph with limited visibility in the background

  svg.style("opacity", 0.01).transition().duration(1000).style("opacity", 0.02).transition().duration(1000).style("opacity", 1);

  // function clickNode(d){

  //   var self = this;

  //   return function(d, i) {

  //       const nodeLocked = self.state.node.index === d.index ? !self.state.nodeLocked : self.state.nodeLocked

  //       self.setState({

  //         node: d,

  //         nodeLocked:nodeLocked

  //       })

  //   }

  // }



  // function clickLink(d){

  // var self = this;

  // return function(d, i) {

  //   const linkLocked = self.state.link.id === d.id ? !self.state.linkLocked : self.state.linkLocked

  //   self.setState({

  //     link: d,

  //     linkLocked: linkLocked

  //   })

  // }

  // }



  // function mouseOverNode(d) {

  // var self = this;

  // return function(d, i) {

  //   if(!self.state.nodeLocked){

  //     self.setState({node: d})

  //   }

  // }

  // }



  // function mouseOverLink(d) {

  //   var self = this;

  //   return function(d, i) {



  //     d3.select(this)

  //       .style("stroke", "#F5352B");



  //     self.setState({link: d})

  //   }

  // }



  // function mouseOutLink(d) {

  // d3.select(this).style("stroke", "#999");

  // }



};



// TODO - replace this with the current ID (depending on implementation)

new Chain(window.projectID);

});