$url = "http://localhost:5678/webhook/cs-inbound"
$run = Get-Date -Format "MMddHHmm"

$tests = @(
  @{ n="1 simple question";   id="e2e-$run-1"; email="elena@northwind-academy.example"; subject="Self-enrollment";
     text="How do I enable self-enrollment for one of our courses?" },
  @{ n="2 low adoption";      id="e2e-$run-2"; email="paolo@brightpath.example"; subject="Getting started";
     text="Only two of our ten staff have logged in since we signed up and we have not published a course yet. Can you suggest how to get the rest of the team started?" },
  @{ n="3 frustrated repeat"; id="e2e-$run-3"; email="rachel@summit-training.example"; subject="Third time writing";
     text="This is the third time I am writing. The export is still broken and nobody has replied. We are considering other options before our renewal." },
  @{ n="4 expansion";         id="e2e-$run-4"; email="ana@harborhealth.example"; subject="Rolling out further";
     text="We are very happy with the platform and plan to roll it out to two more departments next quarter. What options do we have to expand our usage?" },
  @{ n="5 billing";           id="e2e-$run-5"; email="james@lakeside-tech.example"; subject="Duplicate charge";
     text="We were charged twice on last month's invoice. Can you refund the duplicate payment?" },
  @{ n="6 low confidence";    id="e2e-$run-6"; email="liza@pioneer-skills.example"; subject="Payroll question";
     text="Does your platform integrate with our payroll system and generate tax forms for our learners?" },
  @{ n="7 invalid input";     id="e2e-$run-7"; email="not-an-email"; subject="Bad sender";
     text="This message has an invalid sender address." },
  @{ n="8 unknown sender";    id="e2e-$run-8"; email="stranger@unknown.example"; subject="Hello";
     text="Hi, I would like to know more about your product." },
  @{ n="9 duplicate of 1";    id="e2e-$run-1"; email="elena@northwind-academy.example"; subject="Self-enrollment";
     text="How do I enable self-enrollment for one of our courses?" }
)

foreach ($t in $tests) {
  $body = @{ message_id=$t.id; sender_email=$t.email; subject=$t.subject; message_body=$t.text } | ConvertTo-Json
  try {
    $r = Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Body $body
    Write-Host "$($t.n): $($r.status)"
  } catch {
    Write-Host "$($t.n): rejected -> $($_.ErrorDetails.Message)"
  }
  Start-Sleep -Seconds 30
}