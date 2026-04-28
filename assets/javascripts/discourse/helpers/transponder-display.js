import { helper } from "@ember/component/helper";

export default helper(function transponderDisplay([longCode, transponders]) {
  if (!longCode) return "";
  if (!transponders || !transponders.length) return longCode;
  const t = transponders.find(tr => tr.long_code === longCode);
  return t ? `#${t.shortcode} — ${longCode}` : longCode;
});
