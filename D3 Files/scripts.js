// Promise.all([
//     d3.json("data.json"),
//     d3.json("world.geojson")
// ]).then(function([data, world]) {
//     const width = 800;
//     const height = 500;

//     const projection = d3.geoMercator()
//         .scale(150)
//         .translate([width / 2, height / 1.5]);

//     const path = d3.geoPath().projection(projection);

//     const svg = d3.select("#map").append("svg")
//         .attr("width", width)
//         .attr("height", height);

//     // Merge your data with the world data
//     world.features = world.features.map(d => {
//         let country = data.find(row => row.Website_country === d.properties.name);
//         if (country) {
//             d.properties.unemp_Difference = country.unemp_Difference;
//         } else {
//             d.properties.unemp_Difference = null;
//         }
//         return d;
//     });

//     // Create color scale
//     const color = d3.scaleSequential(d3.interpolateReds)
//         .domain([0, d3.max(data, d => d.unemp_Difference)]);

//     svg.selectAll("path")
//         .data(world.features)
//         .enter()
//         .append("path")
//         .attr("d", path)
//         .style("fill", d => color(d.properties.unemp_Difference))
//         .append("title")
//         .text(d => `${d.properties.name}: ${d.properties.unemp_Difference}`);
// });

Promise.all([
    d3.json("data.json"),
    d3.json("world.geojson"),
    d3.json("country_data_diff.json")
]).then(function([data, world, data2]) {
    const width = 800;
    const height = 500;

    console.log(data, data2)
    const projection = d3.geoMercator()
        .scale(150)
        .translate([width / 2, height / 1.5]);

    const path = d3.geoPath().projection(projection);

    const svg = d3.select("#map").append("svg")
        .attr("width", width)
        .attr("height", height);

    // Color scale
    const color = d3.scaleSequential(d3.interpolateRdYlGn)
        .domain([d3.max(data, d => d.unemp_Difference), d3.min(data, d => d.unemp_Difference)]);

    // Add legend
    const legend = d3.select("#legend")
        .append("svg")
        .attr("width", 200)
        .attr("height", 50);

    const gradient = legend.append("defs")
      .append("linearGradient")
      .attr("id", "gradient");

    gradient.append("stop")
      .attr("offset", "0%")
      .attr("stop-color", color.range()[0]);

    gradient.append("stop")
      .attr("offset", "100%")
      .attr("stop-color", color.range()[1]);

    legend.append("rect")
      .attr("x", 10)
      .attr("y", 10)
      .attr("width", 180)
      .attr("height", 20)
      .attr("fill", "url(#gradient)");

    // Function to update map
    function updateMap(scamsDifference) {
        const filteredData = data.filter(d => d.scams_Difference >= scamsDifference);
        
        world.features = world.features.map(d => {
            let country = filteredData.find(row => row.Website_country === d.properties.name);
            if (country) {
                d.properties.unemp_Difference = country.unemp_Difference;
            } else {
                d.properties.unemp_Difference = null;
            }
            return d;
        });

        const paths = svg.selectAll("path")
            .data(world.features, d => d.id);

        paths.enter()
            .append("path")
            .merge(paths)
            .attr("d", path)
            .style("fill", d => d.properties.unemp_Difference === null ? '#ddd' : color(d.properties.unemp_Difference))
            .append("title")
            .text(d => `${d.properties.name}: ${d.properties.unemp_Difference}`);

        paths.exit().remove();
    }

    // Initial rendering
    updateMap(-2);

    // Slider interaction
    const slider = d3.select("#scamSlider");
    slider.on("input", function() {
        const value = +this.value;
        d3.select("#sliderValue").text(value.toFixed(1));
        updateMap(value);
    });
});


const width = 800;
const height = 600;

// Load the data
d3.json("country_data_diff.json").then(data => {
    const nodes = Array.from(new Set(data.flatMap(d => [d.Website_country, d.Phone_country])),
        name => ({
            name
        }));

    const links = data.map(d => ({
        source: nodes.findIndex(n => n.name === d.Website_country),
        target: nodes.findIndex(n => n.name === d.Phone_country),
        value: d.Count
    }));

    const sankeyData = {
        nodes: nodes,
        links: links
    };

    const sankeyLayout = d3.sankey()
        .nodeWidth(15)
        .nodePadding(15)
        .size([width, height])
        .nodeId(d => d.name)
        .nodeAlign(d3.sankeyJustify);

    const {nodes: laidOutNodes, links: laidOutLinks} = sankeyLayout(sankeyData);

    const svg = d3.select("#sankey");

    // Draw the links
    svg.append("g")
        .attr("fill", "none")
        .attr("stroke", "#aaa")
        .attr("stroke-opacity", 0.4)
        .selectAll("path")
        .data(laidOutLinks)
        .join("path")
        .attr("d", d3.sankeyLinkHorizontal())
        .attr("stroke-width", d => Math.max(1, d.width));

    // Draw the nodes
    const node = svg.append("g")
        .selectAll("g")
        .data(laidOutNodes)
        .join("g");

    node.append("rect")
        .attr("x", d => d.x0)
        .attr("y", d => d.y0)
        .attr("height", d => d.y1 - d.y0)
        .attr("width", d => d.x1 - d.x0)
        .attr("fill", d => d3.schemeSet3[nodes.findIndex(n => n.name === d.name)])
        .attr("stroke", "#000");

    node.append("text")
        .attr("x", d => d.x0 - 6)
        .attr("y", d => (d.y1 + d.y0) / 2)
        .attr("dy", "0.35em")
        .attr("text-anchor", "end")
        .text(d => d.name)
        .filter(d => d.x0 < width / 2)
        .attr("x", d => d.x1 + 6)
        .attr("text-anchor", "start");
});