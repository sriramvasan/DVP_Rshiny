
Promise.all([
    d3.json("country_data_diff.json"),
    d3.json("data.json")
]).then(function([data, data2]) {
    console.log(data2)
    console.log(data)
    const width = 800;
    const height = 600;

    if (!Array.isArray(data2)) {
        console.error("Loaded data is not an array");
        return;
    }

    const nodes = Array.from(new Set(data2.flatMap(d => [d.Website_country, d.Phone_country])),
        name => ({
            name
        }));

    const links = data2.map(d => ({
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



// Promise.all([
//     d3.json("country_data_diff.json")
// ]).then(function([data]) {
//     const nodes = Array.from(new Set(data.flatMap(d => [d.Website_country, d.Phone_country])),
//         name => ({
//             name
//         }));

//     const links = data.map(d => ({
//         source: nodes.findIndex(n => n.name === d.Website_country),
//         target: nodes.findIndex(n => n.name === d.Phone_country),
//         value: d.Count
//     }));

//     const sankeyData = {
//         nodes: nodes,
//         links: links
//     };

//     const sankeyLayout = d3.sankey()
//         .nodeWidth(15)
//         .nodePadding(15)
//         .size([width, height])
//         .nodeId(d => d.name)
//         .nodeAlign(d3.sankeyJustify);

//     const {nodes: laidOutNodes, links: laidOutLinks} = sankeyLayout(sankeyData);

//     const svg = d3.select("#sankey");

//     // Draw the links
//     svg.append("g")
//         .attr("fill", "none")
//         .attr("stroke", "#aaa")
//         .attr("stroke-opacity", 0.4)
//         .selectAll("path")
//         .data(laidOutLinks)
//         .join("path")
//         .attr("d", d3.sankeyLinkHorizontal())
//         .attr("stroke-width", d => Math.max(1, d.width));

//     // Draw the nodes
//     const node = svg.append("g")
//         .selectAll("g")
//         .data(laidOutNodes)
//         .join("g");

//     node.append("rect")
//         .attr("x", d => d.x0)
//         .attr("y", d => d.y0)
//         .attr("height", d => d.y1 - d.y0)
//         .attr("width", d => d.x1 - d.x0)
//         .attr("fill", d => d3.schemeSet3[nodes.findIndex(n => n.name === d.name)])
//         .attr("stroke", "#000");

//     node.append("text")
//         .attr("x", d => d.x0 - 6)
//         .attr("y", d => (d.y1 + d.y0) / 2)
//         .attr("dy", "0.35em")
//         .attr("text-anchor", "end")
//         .text(d => d.name)
//         .filter(d => d.x0 < width / 2)
//         .attr("x", d => d.x1 + 6)
//         .attr("text-anchor", "start");
// });
