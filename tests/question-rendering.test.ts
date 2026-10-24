import { describe, expect, it } from "vitest";
import { renderQuestionText } from "../lib/questions/render";

describe("renderQuestionText", () => {
  it("preserves ordinary prose and escapes HTML", () => {
    expect(renderQuestionText("If x < 2, then y > 1.")).toContain("If x &lt; 2, then y &gt; 1.");
    expect(renderQuestionText("<img src=x onerror=alert(1)>")).not.toContain("<img");
  });

  it("renders only explicitly delimited math with KaTeX", () => {
    const html = renderQuestionText("Find $x^2$ for a particle.");
    expect(html).toContain("katex");
    expect(html).toContain("for a particle.");
  });

  it("supports display math and line breaks", () => {
    expect(renderQuestionText("Step 1\n$$x^2+y^2=z^2$$")).toContain("<br />");
    expect(renderQuestionText("Step 1\n$$x^2+y^2=z^2$$")).toContain("katex-display");
  });
});
