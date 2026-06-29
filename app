const STORAGE_KEY = "shoulderArmSplitTracker.v1";
const MAX_INITIAL_WEEKS = 12;

const program = [
  {
    id: "upper-strength",
    name: "Day 1 - Upper Strength",
    notes: "Compounds first, then efficient shoulder and arm work. Aim 0-1 RIR on working sets.",
    exercises: [
      ex("Bench Press", 3, "5-8", "Chest / triceps"),
      ex("Weighted Pull-ups", 3, "5-8", "Back / biceps"),
      ex("Standing Overhead Press", 2, "6-8", "Shoulders"),
      ex("Chest Supported Row", 2, "8-10", "Back"),
      ex("Cable Lateral Raise", 2, "12-15", "Side delts"),
      ex("EZ Bar Curl", 2, "8-12", "Biceps"),
      ex("Skull Crushers", 2, "8-12", "Triceps")
    ]
  },
  {
    id: "legs",
    name: "Day 2 - Legs",
    notes: "All leg work in one session. Keep compounds hard but tidy. No heroic jelly-knee theatre needed.",
    exercises: [
      ex("Back Squat", 3, "5-8", "Quads / glutes"),
      ex("Romanian Deadlift", 3, "6-8", "Hamstrings / glutes"),
      ex("Leg Press", 2, "10-12", "Quads"),
      ex("Seated Leg Curl", 2, "10-12", "Hamstrings"),
      ex("Leg Extension", 2, "12-15", "Quads"),
      ex("Standing Calf Raise", 2, "10-15", "Calves"),
      ex("Hanging Leg Raises", 2, "10-15", "Abs")
    ]
  },
  {
    id: "shoulders-arms",
    name: "Day 3 - Shoulders & Arms",
    notes: "Priority day. Delts and arms get the crown. Isolation sets can go to technical failure.",
    exercises: [
      ex("Seated Dumbbell Shoulder Press", 3, "6-8", "Shoulders"),
      ex("Weighted Chin-ups", 2, "6-8", "Back / biceps"),
      ex("Incline Dumbbell Press", 2, "8-10", "Chest / shoulders"),
      ex("Machine Lateral Raise", 3, "12-15", "Side delts"),
      ex("Rear Delt Fly", 2, "12-15", "Rear delts"),
      ex("Incline Curl", 2, "10-12", "Biceps"),
      ex("Cable Hammer Curl", 2, "10-12", "Biceps / brachialis"),
      ex("Overhead Cable Extension", 2, "10-12", "Triceps long head"),
      ex("Rope Pushdown", 2, "12-15", "Triceps")
    ]
  },
  {
    id: "upper-hypertrophy",
    name: "Day 4 - Upper Hypertrophy",
    notes: "Second chest/back exposure with extra delt and arm volume. Controlled reps, clean failure.",
    exercises: [
      ex("Incline Bench Press", 3, "6-10", "Chest / shoulders"),
      ex("Chest Supported T-Bar Row", 3, "6-10", "Back"),
      ex("Machine Chest Press", 2, "10-12", "Chest"),
      ex("Neutral Grip Pulldown", 2, "10-12", "Back"),
      ex("Cable Lateral Raise", 2, "15-20", "Side delts"),
      ex("Preacher Curl", 2, "10-12", "Biceps"),
      ex("Close Grip Bench Press", 2, "8-10", "Triceps / chest")
    ]
  }
];

function ex(name, sets, reps, target) {
  return { id: slug(name), name, sets, reps, target };
}

function slug(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

function defaultData() {
  return { weeks: MAX_INITIAL_WEEKS, logs: {} };
}

function loadData() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || defaultData();
  } catch {
    return defaultData();
  }
}

function saveData() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}

let data = loadData();

const weekSelect = document.getElementById("weekSelect");
const daySelect = document.getElementById("daySelect");
const exerciseList = document.getElementById("exerciseList");
const workoutTitle = document.getElementById("workoutTitle");
const workoutNotes = document.getElementById("workoutNotes");
const sessionSetCount = document.getElementById("sessionSetCount");

function init() {
  populateWeeks();
  populateDays();
  weekSelect.value = "1";
  daySelect.value = program[0].id;
  renderWorkout();
  registerEvents();
  registerServiceWorker();
}

function populateWeeks() {
  weekSelect.innerHTML = "";
  for (let i = 1; i <= data.weeks; i++) {
    const option = document.createElement("option");
    option.value = String(i);
    option.textContent = `Week ${i}`;
    weekSelect.appendChild(option);
  }
}

function populateDays() {
  daySelect.innerHTML = "";
  program.forEach(day => {
    const option = document.createElement("option");
    option.value = day.id;
    option.textContent = day.name;
    daySelect.appendChild(option);
  });
}

function selectedWeek() {
  return Number(weekSelect.value);
}

function selectedDay() {
  return program.find(day => day.id === daySelect.value) || program[0];
}

function getSetLog(week, dayId, exerciseId, setIndex) {
  return data.logs?.[week]?.[dayId]?.[exerciseId]?.sets?.[setIndex] || { weight: "", reps: "" };
}

function getExerciseNotes(week, dayId, exerciseId) {
  return data.logs?.[week]?.[dayId]?.[exerciseId]?.notes || "";
}

function setExerciseLog(week, dayId, exerciseId, setIndex, field, value) {
  data.logs[week] ??= {};
  data.logs[week][dayId] ??= {};
  data.logs[week][dayId][exerciseId] ??= { sets: [], notes: "" };
  data.logs[week][dayId][exerciseId].sets[setIndex] ??= { weight: "", reps: "" };
  data.logs[week][dayId][exerciseId].sets[setIndex][field] = value;
  saveData();
  updatePreviousPills();
}

function setNotes(week, dayId, exerciseId, value) {
  data.logs[week] ??= {};
  data.logs[week][dayId] ??= {};
  data.logs[week][dayId][exerciseId] ??= { sets: [], notes: "" };
  data.logs[week][dayId][exerciseId].notes = value;
  saveData();
}

function previousSummary(week, dayId, exerciseId) {
  const previousWeek = week - 1;
  if (previousWeek < 1) return "No previous week";
  const exercise = data.logs?.[previousWeek]?.[dayId]?.[exerciseId];
  if (!exercise?.sets?.length) return "No previous data";

  const completed = exercise.sets
    .map((set, index) => set?.weight || set?.reps ? `S${index + 1}: ${set.weight || "-"}kg x ${set.reps || "-"}` : null)
    .filter(Boolean);

  return completed.length ? completed.join(" | ") : "No previous data";
}

function renderWorkout() {
  const day = selectedDay();
  const week = selectedWeek();
  workoutTitle.textContent = day.name;
  workoutNotes.textContent = day.notes;
  sessionSetCount.textContent = day.exercises.reduce((sum, item) => sum + item.sets, 0);
  exerciseList.innerHTML = "";

  const template = document.getElementById("exerciseTemplate");

  day.exercises.forEach(exercise => {
    const node = template.content.cloneNode(true);
    const card = node.querySelector(".exercise-card");
    card.dataset.exerciseId = exercise.id;
    node.querySelector(".exercise-name").textContent = exercise.name;
    node.querySelector(".exercise-meta").textContent = `${exercise.sets} sets | ${exercise.reps} reps | ${exercise.target}`;
    node.querySelector(".previous-pill").textContent = previousSummary(week, day.id, exercise.id);

    const setsContainer = node.querySelector(".sets");
    for (let i = 0; i < exercise.sets; i++) {
      const log = getSetLog(week, day.id, exercise.id, i);
      const row = document.createElement("div");
      row.className = "set-row";
      row.innerHTML = `
        <div class="set-number">S${i + 1}</div>
        <label>Weight kg<input inputmode="decimal" type="number" step="0.5" min="0" value="${escapeHtml(log.weight)}" data-field="weight" data-set="${i}" /></label>
        <label>Reps<input inputmode="numeric" type="number" step="1" min="0" value="${escapeHtml(log.reps)}" data-field="reps" data-set="${i}" /></label>
        <div class="previous-text">Prev: ${escapeHtml(getPreviousSetText(week, day.id, exercise.id, i))}</div>
      `;
      setsContainer.appendChild(row);
    }

    const notes = node.querySelector(".notes-input");
    notes.value = getExerciseNotes(week, day.id, exercise.id);
    notes.addEventListener("input", event => setNotes(week, day.id, exercise.id, event.target.value));

    setsContainer.addEventListener("input", event => {
      const input = event.target;
      if (!input.matches("input")) return;
      setExerciseLog(week, day.id, exercise.id, Number(input.dataset.set), input.dataset.field, input.value);
    });

    exerciseList.appendChild(node);
  });
}

function getPreviousSetText(week, dayId, exerciseId, setIndex) {
  if (week <= 1) return "-";
  const previous = getSetLog(week - 1, dayId, exerciseId, setIndex);
  if (!previous.weight && !previous.reps) return "-";
  return `${previous.weight || "-"}kg x ${previous.reps || "-"}`;
}

function updatePreviousPills() {
  const week = selectedWeek();
  const day = selectedDay();
  document.querySelectorAll(".exercise-card").forEach(card => {
    const pill = card.querySelector(".previous-pill");
    pill.textContent = previousSummary(week, day.id, card.dataset.exerciseId);
  });
}

function copyPreviousWeek() {
  const week = selectedWeek();
  if (week <= 1) return alert("Week 1 has no previous week to copy.");
  const dayId = selectedDay().id;
  const previous = data.logs?.[week - 1]?.[dayId];
  if (!previous) return alert("No previous data found for this workout.");
  data.logs[week] ??= {};
  data.logs[week][dayId] = structuredClone(previous);
  saveData();
  renderWorkout();
}

function exportData() {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "workout-tracker-data.json";
  link.click();
  URL.revokeObjectURL(url);
}

function importData(file) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const imported = JSON.parse(reader.result);
      if (!imported.logs || !imported.weeks) throw new Error("Invalid data");
      data = imported;
      saveData();
      populateWeeks();
      renderWorkout();
      alert("Data imported successfully.");
    } catch {
      alert("That file does not look like valid tracker data.");
    }
  };
  reader.readAsText(file);
}

function clearCurrentWeek() {
  const week = selectedWeek();
  const dayId = selectedDay().id;
  if (!confirm(`Clear Week ${week} data for ${selectedDay().name}?`)) return;
  if (data.logs?.[week]?.[dayId]) delete data.logs[week][dayId];
  saveData();
  renderWorkout();
}

function addWeek() {
  data.weeks += 1;
  saveData();
  populateWeeks();
  weekSelect.value = String(data.weeks);
  renderWorkout();
}

function registerEvents() {
  weekSelect.addEventListener("change", renderWorkout);
  daySelect.addEventListener("change", renderWorkout);
  document.getElementById("addWeekBtn").addEventListener("click", addWeek);
  document.getElementById("copyPreviousBtn").addEventListener("click", copyPreviousWeek);
  document.getElementById("exportBtn").addEventListener("click", exportData);
  document.getElementById("resetWeekBtn").addEventListener("click", clearCurrentWeek);
  document.getElementById("importInput").addEventListener("change", event => {
    const file = event.target.files?.[0];
    if (file) importData(file);
    event.target.value = "";
  });
}

function registerServiceWorker() {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>'"]/g, char => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;"
  }[char]));
}

init();
