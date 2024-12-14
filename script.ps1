param($configPath)
$MIN_SEATS = 1;
Write-Host "Reading configuration from path $configPath";

$config = Get-Content -Path ($configPath) -Raw | ConvertFrom-Json;
$data = Get-Content -Path ($config.pathToData) -Raw | ConvertFrom-Json;

$max_population = 0;
$seats_after_guaranteed = $config.maxSeats_nat;

# Add Min
foreach ($country in $data) {
    $max_population += $country.population;

    $country.seats = $MIN_SEATS;
    $seats_after_guaranteed -= $MIN_SEATS;
}

# Calculate Population Percentage
foreach ($c in $data) {
    $c.percentage_population = $c.population / $max_population;
}

# Allocate Seats with Hare/Niemeyer-Procedure
$count = $data.Count;
$divisor = $max_population / $seats_after_guaranteed;
$total_seats = 0;


foreach ($count in $data) {
    $seats = [math]::floor($count.population / $divisor);
    $count.seats += $seats;
    #    Write-Host "Seats $seats ";
}

# Calc comma seats
foreach ($c in $data) {
    $total_seats += $c.seats;
    $comma = ($c.population / $divisor) - $c.seats;
    $c.comma = $comma;
}

# Sort by the 'Comma' property
while ($total_seats -lt $config.maxSeats_nat) {
    # Sort by Least overrepresented
    Write-Host "After allocating: $total_seats/"$config.maxSeats_nat;
    Write-Host "Add Seat to "$data[0].name;
    $data = $data | Sort-Object -Property Comma -Descending

    # Add Seats and update comma
    $data[0].seats += 1;
    $total_seats += 1;
    $comma = ($data[0].population / $divisor) - $data[0].seats;
    $data[0].comma = $comma;
    
    #    Write-Host "Div: $div Seats: $"$c.seats" Comma:$comma";
}

Write-Host "After allocating: $total_seats/"$config.maxSeats_nat;
$data | ForEach-Object {
    Write-Output "Name: $($_.Name), Seats: $($_.Seats)"
}