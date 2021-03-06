#
# Copyright (c) Ionplus AG and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

delimiter //

# summary:
# Calculates the sums and errors of all active runs of the specified target.
#
# params:
# - $target_id: The identifier of the target.
create procedure calculate_target($target_id int)
begin
    declare $active_runs int default 0;
    declare $total_runs int default 0;

    declare $runtime double default 0;

    declare $r int;
    declare $g1 int;
    declare $g2 int;

    declare $ana double;
    declare $a double;
    declare $b double;
    declare $c double;

    declare $ratio_g1_a double;
    declare $ratio_g1_b double;
    declare $ratio_g2_a double;
    declare $ratio_g2_b double;

    declare $ratio_r_a double;
    declare $ratio_r_a_sum double;
    declare $ratio_r_a_sum2 double;
    declare $ratio_r_a_sigma double;

    declare $ratio_r_b double;
    declare $ratio_r_b_sum double;
    declare $ratio_r_b_sum2 double;
    declare $ratio_r_b_sigma double;

    declare $ratio_b_a double;
    declare $ratio_b_a_sum double;
    declare $ratio_b_a_sum2 double;
    declare $ratio_b_a_sigma double;

    declare $transmission double;
    declare $transmission_sum double;
    declare $transmission_sum2 double;
    declare $transmission_sigma double;

    declare $weight_sum double;

    calculate:
    begin
        # check if there is something to do
        select count(*)
        into $active_runs
        from run where target_id = $target_id and active is true;

        if $active_runs < 1 then
            leave calculate;
        end if;

        # calculate the sums
        select sum(runtime),
               if(count(a) = $active_runs, sum(a * runtime), null),
               if(count(r) = $active_runs, sum(r), null),
               if(count(g1) = $active_runs, sum(g1), null),
               if(count(g2) = $active_runs, sum(g2), null)
        into $runtime, $weight_sum, $r, $g1, $g2
        from run where target_id = $target_id and enabled;

        select count(*)
        into $total_runs
        from run where target_id = $target_id;

        # calculate the means
        # for the currents, the weight is the runtime,
        # for the ratios the weight is a*runtime (aka weight_sum).
        set $a = $weight_sum / $runtime;
        select if(count(ana) = $active_runs, sum(ana * runtime) / $runtime, null),
               if(count(b) = $active_runs, sum(b * runtime) / $runtime, null),
               if(count(c) = $active_runs, sum(c * runtime) / $runtime, null)
        into $ana, $b, $c
        from run where target_id = $target_id and enabled;

        if $weight_sum > 0 then

            select if(count(ratio_r_a) = $active_runs, sum(ratio_r_a * a * runtime) / $weight_sum, null),
                   if(count(ratio_r_a) = $active_runs, sum(ratio_r_a * a * runtime), null),
                   if(count(ratio_r_a) = $active_runs, sum(ratio_r_a * ratio_r_a * a * runtime), null)
            into $ratio_r_a, $ratio_r_a_sum, $ratio_r_a_sum2
            from run where target_id = $target_id and enabled;

            select if(count(ratio_r_b) = $active_runs, sum(ratio_r_b * a * runtime) / $weight_sum, null),
                   if(count(ratio_r_b) = $active_runs, sum(ratio_r_b * a * runtime), null),
                   if(count(ratio_r_b) = $active_runs, sum(ratio_r_b * ratio_r_b * a * runtime), null)
            into $ratio_r_b, $ratio_r_b_sum, $ratio_r_b_sum2
            from run where target_id = $target_id and enabled;

            select if(count(ratio_g1_a) = $active_runs, sum(ratio_g1_a * a * runtime) / $weight_sum, null),
                   if(count(ratio_g1_b) = $active_runs, sum(ratio_g1_b * a * runtime) / $weight_sum, null)
            into $ratio_g1_a, $ratio_g1_b
            from run where target_id = $target_id and enabled;

            select if(count(ratio_g2_a) = $active_runs, sum(ratio_g2_a * a * runtime) / $weight_sum, null),
                   if(count(ratio_g2_b) = $active_runs, sum(ratio_g2_b * a * runtime) / $weight_sum, null)
            into $ratio_g2_a, $ratio_g2_b
            from run where target_id = $target_id and enabled;

            select if(count(ratio_b_a) = $active_runs, sum(ratio_b_a * a * runtime) / $weight_sum, null),
                   if(count(ratio_b_a) = $active_runs, sum(ratio_b_a * a * runtime), null),
                   if(count(ratio_b_a) = $active_runs, sum(ratio_b_a * ratio_b_a * a * runtime), null)
            into $ratio_b_a, $ratio_b_a_sum, $ratio_b_a_sum2
            from run where target_id = $target_id and enabled;

            select if(count(transmission) = $active_runs, sum(transmission * a * runtime) / $weight_sum, null),
                   if(count(transmission) = $active_runs, sum(transmission * a * runtime), null),
                   if(count(transmission) = $active_runs, sum(transmission * transmission * a * runtime), null)
            into $transmission, $transmission_sum, $transmission_sum2
            from run where target_id = $target_id and enabled;

            # calculate the sigmas, but only of there are at least 2 cycles
            if $active_runs >= 2 then

                if $ratio_r_a > 0 then
                    set $ratio_r_a_sigma = sqrt(
                            ($ratio_r_a_sum2 - (pow($ratio_r_a_sum, 2) / $weight_sum)) / ($weight_sum * ($active_runs - 1))
                        ) / $ratio_r_a * 100;
                end if;

                if $ratio_r_b > 0 then
                    set $ratio_r_b_sigma = sqrt(
                            ($ratio_r_b_sum2 - (pow($ratio_r_b_sum, 2) / $weight_sum)) / ($weight_sum * ($active_runs - 1))
                        ) / $ratio_r_b * 100;
                end if;

                if $ratio_b_a > 0 then
                    set $ratio_b_a_sigma = sqrt(
                        ($ratio_b_a_sum2 - (pow($ratio_b_a_sum, 2) / $weight_sum)) / ($weight_sum * ($active_runs - 1))
                    ) / $ratio_b_a * 100;
                end if;

                if $transmission > 0 then
                    set $transmission_sigma = sqrt(
                        ($transmission_sum2 - (pow($transmission_sum, 2) / $weight_sum)) / ($weight_sum * ($active_runs - 1))
                    ) / $transmission * 100;
                end if;

            end if; -- $enabled_runs >= 2

        end if; -- $weight_sum > 0
    end; -- calculate

    update target
    set active_runs = $active_runs,
        total_runs = $total_runs,
        runtime = $runtime,
        r = $r,
        g1 = $g1,
        g2 = $g2,
        a = $a,
        b = $b,
        ana = $ana,
        c = $c,
        ratio_r_a = $ratio_r_a,
        ratio_r_a_sigma = $ratio_r_a_sigma,
        ratio_r_b = $ratio_r_b,
        ratio_r_b_sigma = $ratio_r_b_sigma,
        ratio_g1_a = $ratio_g1_a,
        ratio_g1_b = $ratio_g1_b,
        ratio_g2_a = $ratio_g2_a,
        ratio_g2_b = $ratio_g2_b,
        ratio_b_a = $ratio_b_a,
        ratio_b_a_sigma = $ratio_b_a_sigma,
        transmission = $transmission,
        transmission_sigma = $transmission_sigma
    where id = $target_id;
end;

//
delimiter ;
