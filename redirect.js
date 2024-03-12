import * as fs from "fs";

export default async function run({
    renderFunctionFilePath,
    routePatterns,
    apiRoutePatterns,
}) {
    console.log("Writing _redirects");

    const redirectsFile = "/* /index.html 200\n";

    fs.writeFileSync("dist/_redirects", redirectsFile);
}

