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
    d3.json("world.geojson")
]).then(function([data, world]) {
    const width = 800;
    const height = 500;

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
