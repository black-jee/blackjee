import { PyqPracticeCard } from "@/components/pyq/pyq-practice-card";
import { toPyqQuestion, type PyqRow } from "@/lib/questions/pyq-adapter";

export function PyqQuestionList({ rows, offset = 0 }: { rows: PyqRow[]; offset?: number }) {
  return (
    <section className="mt-6 space-y-4" aria-label="Question results">
      {rows.map((row, index) => (
        <PyqPracticeCard
          key={row.id}
          id={row.id}
          number={offset + index + 1}
          title={row.title}
          exam={row.exam}
          year={row.year}
          question={toPyqQuestion(row)}
        />
      ))}
    </section>
  );
}
