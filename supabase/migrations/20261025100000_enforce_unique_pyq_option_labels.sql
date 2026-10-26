-- Enforce unambiguous multiple-choice option labels for every database write.
-- This is a forward-only integrity guard; it does not modify existing question content.
CREATE OR REPLACE FUNCTION public.validate_jee_pyq_option_labels()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
BEGIN
  IF NEW.question_type = 'single_correct' THEN
    IF jsonb_typeof(NEW.options) IS DISTINCT FROM 'array' THEN
      RAISE EXCEPTION 'Single-correct questions need an options array'
        USING ERRCODE = '22023';
    END IF;

    IF jsonb_array_length(NEW.options) < 2 THEN
      RAISE EXCEPTION 'Single-correct questions need at least two options'
        USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_array_elements(NEW.options) AS option_item(item)
      WHERE nullif(btrim(coalesce(option_item.item->>'label', option_item.item->>'letter', '')), '') IS NULL
    ) THEN
      RAISE EXCEPTION 'Single-correct options need non-empty labels'
        USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_array_elements(NEW.options) AS option_item(item)
      GROUP BY upper(btrim(coalesce(option_item.item->>'label', option_item.item->>'letter', '')))
      HAVING count(*) > 1
    ) THEN
      RAISE EXCEPTION 'Single-correct option labels must be unique'
        USING ERRCODE = '22023';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.validate_jee_pyq_option_labels() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS validate_jee_pyq_option_labels ON public.jee_pyq_questions;
CREATE TRIGGER validate_jee_pyq_option_labels
BEFORE INSERT OR UPDATE OF question_type, options
ON public.jee_pyq_questions
FOR EACH ROW
EXECUTE FUNCTION public.validate_jee_pyq_option_labels();
