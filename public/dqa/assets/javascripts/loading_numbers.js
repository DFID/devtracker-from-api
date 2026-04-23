//
// For guidance on how to add JavaScript see:
// https://prototype-kit.service.gov.uk/docs/adding-css-javascript-and-images
//


// HERO COUNTERS
let count1 = 0;
let count2 = 0;
let count3 = 0;
let count4 = 0;
let count5 = 0;
let count6 = 0;
let count7 = 0;
let count8 = 0;
const target1 = 90;
const target2 = 10;
const target3 = 95;
const target4 = 5;
const target5 = 95;
const target6 = 5;
const target7 = 85;
const target8 = 15;
const counterElement1 = document.getElementById("counter_1");
const counterElement2 = document.getElementById("counter_2");
const counterElement3 = document.getElementById("counter_3");
const counterElement4 = document.getElementById("counter_4");
const counterElement5 = document.getElementById("counter_5");
const counterElement6 = document.getElementById("counter_6");
const counterElement7 = document.getElementById("counter_7");
const counterElement8 = document.getElementById("counter_8");

const interval1 = setInterval(() => {
     counterElement1.textContent = count1;
     count1++;
     if (count1 > target1) { clearInterval(interval1); }
}, 25);

const interval2 = setInterval(() => {
     counterElement2.textContent = count2;
     count2++;
     if (count2 > target2) { clearInterval(interval2); }
}, 25);

const interval3 = setInterval(() => {
     counterElement3.textContent = count3;
     count3++;
     if (count3 > target3) { clearInterval(interval3); }
}, 25);

const interval4 = setInterval(() => {
     counterElement4.textContent = count4;
     count4++;
     if (count4 > target4) { clearInterval(interval4); }
}, 25);

const interval5 = setInterval(() => {
     counterElement5.textContent = count5;
     count5++;
     if (count5 > target5) { clearInterval(interval5); }
}, 25);

const interval6 = setInterval(() => {
     counterElement6.textContent = count6;
     count6++;
     if (count6 > target6) { clearInterval(interval6); }
}, 25);

const interval7 = setInterval(() => {
     counterElement7.textContent = count7;
     count7++;
     if (count7 > target7) { clearInterval(interval7); }
}, 25);

const interval8 = setInterval(() => {
     counterElement8.textContent = count8;
     count8++;
     if (count8 > target8) { clearInterval(interval8); }
}, 25);

