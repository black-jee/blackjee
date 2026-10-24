import katex from "katex";

const MATH_DELIMITER = /(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\\\([\s\S]+?\\\)|\$[^$\n]+\$)/g;

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** Renders plain question prose safely and converts only explicitly delimited math to KaTeX. */
export function renderQuestionText(source: string): string {
  return source.split(MATH_DELIMITER).map((part) => {
    if (!part) return "";
    const isDisplay = part.startsWith("$$") || part.startsWith("\\[");
    let expression: string | undefined;

    if (part.startsWith("$$") && part.endsWith("$$")) expression = part.slice(2, -2);
    else if (part.startsWith("\\[") && part.endsWith("\\]")) expression = part.slice(2, -2);
    else if (part.startsWith("\\(") && part.endsWith("\\)")) expression = part.slice(2, -2);
    else if (part.startsWith("$") && part.endsWith("$")) expression = part.slice(1, -1);

    if (expression === undefined) {
      return escapeHtml(part).replace(/\r?\n/g, "<br />");
    }

    try {
      return katex.renderToString(expression, {
        displayMode: isDisplay,
        throwOnError: false,
        strict: "warn",
        trust: false,
        output: "htmlAndMathml",
      });
    } catch {
      return escapeHtml(part).replace(/\r?\n/g, "<br />");
    }
  }).join("");
}
