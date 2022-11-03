#-----------------------------------------------------------------------#
#  file: OCPWindTurbine_Data.rb                                         #
#                                                                       #
#  version: 1.0   date 3/11/2022                                        #
#                                                                       #
#  Copyright (C) 2022                                                   #
#                                                                       #
#      Enrico Bertolazzi, Francesco Biral and Paolo Bosetti             #
#      Dipartimento di Ingegneria Industriale                           #
#      Universita` degli Studi di Trento                                #
#      Via Sommarive 9, I-38123, Trento, Italy                          #
#      email: enrico.bertolazzi@unitn.it                                #
#             francesco.biral@unitn.it                                  #
#             paolo.bosetti@unitn.it                                    #
#-----------------------------------------------------------------------#


include Mechatronix

# User Header

# Auxiliary values
gen__torque__dot__max    = 10
tol_x_i                  = 0.1
tol_gen__torque__dotdot  = 0.1
thrust__max              = 700
tol_thrust               = thrust__max*tol_x_i
beta__dot__max           = 1.5
epsi_x_i                 = 0.01
epsi_x                   = epsi_x_i
tol_beta__dotdot         = 0.1
OmegaMAP__max            = 1/5.0*Math::PI
Omega__max               = 1/2.0*Math::PI
tol_Omega                = Omega__max*tol_x_i
theta__max               = 60
tol_theta                = theta__max*tol_x_i
beta__max                = 8
tol_beta                 = beta__max*tol_x_i
tol_gen__torque__dot     = gen__torque__dot__max*tol_x_i
tol_OmegaMAP             = OmegaMAP__max*tol_x_i
gen__torque__max         = 43
tol_gen__torque          = gen__torque__max*tol_x_i
epsi_u_i                 = 0.1
epsi_u                   = epsi_u_i
gen__torque__dotdot__max = 3
pow__max                 = 6
tol_pow                  = pow__max*tol_x_i
tol_beta__dot            = beta__dot__max*tol_x_i
beta__dotdot__max        = 1.5

mechatronix do |data|

  data.Debug     = false  # activate run time debug
  data.Doctor    = false  # Enable doctor
  data.InfoLevel = 4      # Level of message
  data.Use_control_penalties_in_adjoint_equations = false
  data.Max_penalty_value = 1000

  #  _   _                        _
  # | |_| |__  _ __ ___  __ _  __| |___
  # | __| '_ \| '__/ _ \/ _` |/ _` / __|
  # | |_| | | | | |  __/ (_| | (_| \__ \
  #  \__|_| |_|_|  \___|\__,_|\__,_|___/

  # maximum number of threads used for linear algebra and various solvers
  data.N_threads   = [1,$MAX_THREAD_NUM-1].max
  data.U_threaded  = true
  data.F_threaded  = true
  data.JF_threaded = true
  data.LU_threaded = true

  # Enable check jacobian and controls
  data.ControlsCheck         = true
  data.ControlsCheck_epsilon = 1e-6
  data.JacobianCheck         = true
  data.JacobianCheckFull     = false
  data.JacobianCheck_epsilon = 1e-4

  # jacobian discretization: 'ANALYTIC', 'ANALYTIC2', 'FINITE_DIFFERENCE'
  data.JacobianDiscretization = 'ANALYTIC'

  # jacobian discretization BC part: 'ANALYTIC', 'FINITE_DIFFERENCE'
  data.JacobianDiscretizationBC = 'ANALYTIC'

  # Dump Function and Jacobian if uncommented
  #data.DumpFile = "OCPWindTurbine_dump"

  # spline output (all values as function of "s")
  data.OutputSplines = [:s]

  #   ____            _             _   ____        _
  #  / ___|___  _ __ | |_ _ __ ___ | | / ___|  ___ | |_   _____ _ __
  # | |   / _ \| '_ \| __| '__/ _ \| | \___ \ / _ \| \ \ / / _ \ '__|
  # | |__| (_) | | | | |_| | | (_) | |  ___) | (_) | |\ V /  __/ |
  #  \____\___/|_| |_|\__|_|  \___/|_| |____/ \___/|_| \_/ \___|_|

  # setup solver for controls
  data.ControlSolver = {
    # ==============================================================
    # 'Hyness', 'NewtonDumped', 'LevenbergMarquardt', 'YixunShi', 'QuasiNewton'
    :solver => 'NewtonDumped',
    # 'LU', 'LUPQ', 'QR', 'QRP', 'SVD', 'LSS', 'LSY', 'PINV' for Hyness and NewtonDumped
    :factorization => 'LU',
    # ==============================================================
    :Iterative => false,
    :InfoLevel => -1, # suppress all messages
    # ==============================================================
    # 'LevenbergMarquardt', 'YixunShi', 'QuasiNewton'
    :initialize_control_solver => 'QuasiNewton',

    # solver parameters
    :NewtonDumped => {
      # "MERIT_D2", "MERIT_F2"
      # "MERIT_LOG_D2", "MERIT_LOG_F2"
      # "MERIT_F2_and_D2", "MERIT_LOG_F2_and_D2", "MERIT_LOG_F2_and_LOG_D2"
      :merit                => "MERIT_D2",
      :max_iter             => 50,
      :max_step_iter        => 10,
      :max_accumulated_iter => 150,
      :tolerance            => 1e-10, # tolerance for stopping criteria
      :c1                   => 0.01,  # Constant for Armijo step acceptance criteria
      :lambda_min           => 1e-10, # minimum lambda for linesearch
      :dump_min             => 0.4,   # (0,0.5)  dumping factor for linesearch
      :dump_max             => 0.9,   # (0.5,0.99)
      # Potenza `n` della funzione di interpolazione per minimizzazione
      # f(x) = f0 * exp( (f0'/f0) * x ) + C * x^n
      :merit_power          => 4, # (2..100)
      # check that search direction and new estimated search direction have an angle less than check_angle
      # if check_angle == 0 no check is done
      :check_angle            => 120,
      :check_ratio_norm_two_f => 1.4,  # check that ratio of ||f(x_{k+1})||_2/||f(x_{k})||_2 <= NUMBER
      :check_ratio_norm_two_d => 1.4,  # check that ratio of ||d(x_{k+1})||_2/||d(x_{k})||_2 <= NUMBER
      :check_ratio_norm_one_f => 1.4,  # check that ratio of ||f(x_{k+1})||_1/||f(x_{k})||_1 <= NUMBER
      :check_ratio_norm_one_d => 1.4,  # check that ratio of ||d(x_{k+1})||_1/||d(x_{k})||_1 <= NUMBER
    },

    :Hyness => {
      :max_iter  => 50,
      :tolerance => 1e-9
    },

    :LevenbergMarquardt => {
      :max_iter  => 50,
      :tolerance => 1e-9
    },

    :YixunShi => {
      :max_iter  => 50,
      :tolerance => 1e-9
    },

    :QuasiNewton => {
      :max_iter  => 50,
      :tolerance => 1e-9,
      # 'BFGS', 'DFP', 'SR1' for Quasi Newton
      :update => 'BFGS',
      # 'EXACT', 'ARMIJO'
      :linesearch => 'EXACT',
    },
  }

  #  ____        _
  # / ___|  ___ | |_   _____ _ __
  # \___ \ / _ \| \ \ / / _ \ '__|
  #  ___) | (_) | |\ V /  __/ |
  # |____/ \___/|_| \_/ \___|_|

  # setup solver
  data.Solver = {
    # Linear algebra factorization selection:
    # 'LU', 'QR', 'QRP', 'SUPERLU'
    # =================
    :factorization => 'LU',
    # =================

    # Last Block selection:
    # 'LU', 'LUPQ', 'QR', 'QRP', 'SVD', 'LSS', 'LSY', 'PINV'
    # ==============================================
    :last_factorization => 'LUPQ', # automatically use PINV if singular
    # ==============================================

    # choose solves: Hyness, NewtonDumped
    # ===================================
    :solver => "NewtonDumped",
    # ===================================

    # solver parameters
    :NewtonDumped => {
      # "MERIT_D2", "MERIT_F2"
      # "MERIT_LOG_D2", "MERIT_LOG_F2"
      # "MERIT_F2_and_D2", "MERIT_LOG_F2_and_D2", "MERIT_LOG_F2_and_LOG_D2"
      :merit                => "MERIT_LOG_F2_and_D2",
      :max_iter             => 1200,
      :max_step_iter        => 240,
      :max_accumulated_iter => 2100,

      :continuation => {
        :initial_step   => 0.2   , # -- initial step for continuation
        :min_step       => 0.001 , # -- minimum accepted step for continuation
        :reduce_factor  => 0.5   , # -- if continuation step fails, reduce step by this factor
        :augment_factor => 1.5   , # -- if step successful in less than few_iteration augment step by this factor
        :few_iterations => 8       # -- if step successful in less than few_iteration augment step by this factor
      },

      # tolerance for stopping criteria
      :tolerance => 1e-09,

      # Constant for Armijo step acceptance criteria
      :c1 => 0.01,

      # minimum lambda for linesearch
      :lambda_min => 1e-10,

      # dumping factor for linesearch
      :dump_min => 0.4, # (0,0.5)
      :dump_max => 0.9, # (0.5,0.99)

      # Potenza `n` della funzione di interpolazione per minimizzazione
      # f(x) = f0 * exp( (f0'/f0) * x ) + C * x^n
      :merit_power => 2, # (2..100)

      # check that search direction and new estimated search direction have an angle less than check_angle
      # if check_angle == 0 no check is done
      :check_angle  => 120,

      # check that ratio of ||f(x_{k+1})||_2/||f(x_{k})||_2 <= NUMBER
      :check_ratio_norm_two_f => 2,
      # check that ratio of ||d(x_{k+1})||_2/||d(x_{k})||_2 <= NUMBER
      :check_ratio_norm_two_d => 2,
      # check that ratio of ||f(x_{k+1})||_1/||f(x_{k})||_1 <= NUMBER
      :check_ratio_norm_one_f => 2,
      # check that ratio of ||d(x_{k+1})||_1/||d(x_{k})||_1 <= NUMBER
      :check_ratio_norm_one_d => 2,
    },

    :Hyness => {
      :max_iter             => 1200,
      :max_step_iter        => 240,
      :max_accumulated_iter => 2100,
      :tolerance            => 1e-09,
      :continuation => {
        :initial_step   => 0.2   , # -- initial step for continuation
        :min_step       => 0.001 , # -- minimum accepted step for continuation
        :reduce_factor  => 0.5   , # -- if continuation step fails, reduce step by this factor
        :augment_factor => 1.5   , # -- if step successful in less than few_iteration augment step by this factor
        :few_iterations => 8       # -- if step successful in less than few_iteration augment step by this factor
      }
    },

    # continuation parameters
    :ns_continuation_begin => 0,
    :ns_continuation_end   => 1,
  }

  #                                       _
  #  _ __   __ _ _ __ __ _ _ __ ___   ___| |_ ___ _ __ ___
  # | '_ \ / _` | '__/ _` | '_ ` _ \ / _ \ __/ _ \ '__/ __|
  # | |_) | (_| | | | (_| | | | | | |  __/ ||  __/ |  \__ \
  # | .__/ \__,_|_|  \__,_|_| |_| |_|\___|\__\___|_|  |___/
  # |_|

  # Boundary Conditions
  data.BoundaryConditions = {
    :initial_theta            => SET,
    :initial_lambda0          => SET,
    :initial_beta             => SET,
    :initial_beta__dot        => SET,
    :initial_Omega            => SET,
    :initial_gen__torque      => SET,
    :initial_gen__torque__dot => SET,
  }

  # Guess
  data.Guess = {
    # possible value: zero, default, none, warm
    :initialize => 'zero',
    # possible value: default, none, warm, spline, table
    :guess_type => 'default',
    # initilize or not lagrange multiplier with redundant linear system
    :initialize_multipliers => false,
    # 'use_guess', 'minimize', 'none'
    :initialize_controls    => 'use_guess'
  }

  data.Parameters = {

    # Model Parameters
    :beta__dotdot__max        => beta__dotdot__max,
    :gen__torque__dotdot__max => gen__torque__dotdot__max,

    # Guess Parameters

    # Boundary Conditions
    :beta__0             => 1.982138,
    :Omega__0            => 1.267109037,
    :beta__dot__0        => 0,
    :gen__torque__0      => 43.093673,
    :lambda0__0          => 2.210000,
    :theta__0            => 53.76449987,
    :gen__torque__dot__0 => 0,

    # Post Processing Parameters
    :OmegaMAP__max         => OmegaMAP__max,
    :OmegaMAP__min         => -1/5.00*Math::PI,
    :Omega__max            => Omega__max,
    :Omega__min            => 0,
    :beta__dot__max        => beta__dot__max,
    :beta__max             => beta__max,
    :beta__min             => -8,
    :pow__max              => pow__max,
    :pow__min              => 0,
    :theta__max            => theta__max,
    :theta__min            => 0,
    :thrust__max           => thrust__max,
    :gen__torque__dot__max => gen__torque__dot__max,
    :gen__torque__max      => gen__torque__max,
    :gen__torque__min      => 0,

    # User Function Parameters

    # Continuation Parameters
    :tol_x_f                 => 0.001,
    :tol_x_i                 => tol_x_i,
    :epsi_u_f                => 0.01,
    :epsi_u_i                => epsi_u_i,
    :epsi_x_f                => 0.001,
    :epsi_x_i                => epsi_x_i,
    :tol_beta__dotdot        => tol_beta__dotdot,
    :tol_gen__torque__dotdot => tol_gen__torque__dotdot,

    # Constraints Parameters
  }

  #                              _
  #  _ __ ___   __ _ _ __  _ __ (_)_ __   __ _
  # | '_ ` _ \ / _` | '_ \| '_ \| | '_ \ / _` |
  # | | | | | | (_| | |_) | |_) | | | | | (_| |
  # |_| |_| |_|\__,_| .__/| .__/|_|_| |_|\__, |
  #                 |_|   |_|            |___/
  # functions mapped on objects
  data.MappedObjects = {}


  #                  _             _
  #   ___ ___  _ __ | |_ _ __ ___ | |___
  #  / __/ _ \| '_ \| __| '__/ _ \| / __|
  # | (_| (_) | | | | |_| | | (_) | \__ \
  #  \___\___/|_| |_|\__|_|  \___/|_|___/
  # Controls
  # Penalty subtype: QUADRATIC, QUADRATIC2, PARABOLA, CUBIC, QUARTIC, BIPOWER
  # Barrier subtype: LOGARITHMIC, LOGARITHMIC2, COS_LOGARITHMIC, TAN2, HYPERBOLIC
  data.Controls = {}
  data.Controls[:beta__dotdotControl] = {
    :type      => 'COS_LOGARITHMIC',
    :epsilon   => epsi_u,
    :tolerance => tol_beta__dotdot
  }

  data.Controls[:gen__torque__dotdotControl] = {
    :type      => 'COS_LOGARITHMIC',
    :epsilon   => epsi_u,
    :tolerance => tol_gen__torque__dotdot
  }



  #                      _             _       _
  #   ___ ___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___
  #  / __/ _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __|
  # | (_| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \
  #  \___\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/
  data.Constraints = {}
  #  _  _____
  # | ||_   _|
  # | |__| |
  # |____|_|
  # Penalty subtype: WALL_ERF_POWER1, WALL_ERF_POWER2, WALL_ERF_POWER3, WALL_TANH_POWER1, WALL_TANH_POWER2, WALL_TANH_POWER3, WALL_PIECEWISE_POWER1, WALL_PIECEWISE_POWER2, WALL_PIECEWISE_POWER3, PENALTY_REGULAR, PENALTY_SMOOTH, PENALTY_PIECEWISE
  # Barrier subtype: BARRIER_1X, BARRIER_LOG, BARRIER_LOG_EXP, BARRIER_LOG0
  # PenaltyBarrier1DLessThan
  data.Constraints[:BetaLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_beta,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:BetaLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_beta,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:BetaDotLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_beta__dot,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:BetaDotLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_beta__dot,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:OmegaMAPLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_OmegaMAP,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:OmegaMAPLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_OmegaMAP,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:OmegaLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_Omega,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:OmegaLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_Omega,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:ThetaLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_theta,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:ThetaLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_theta,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:PowerLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_pow,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:PowerLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_pow,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:ThrustLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_thrust,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:ThrustLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_thrust,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:TorqueDotLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_gen__torque__dot,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:TorqueDotLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_gen__torque__dot,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:TorqueLimit_min] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_gen__torque,
    :active    => true
  }
  # PenaltyBarrier1DLessThan
  data.Constraints[:TorqueLimit_max] = {
    :subType   => "PENALTY_REGULAR",
    :epsilon   => epsi_x,
    :tolerance => tol_gen__torque,
    :active    => true
  }
  # Constraint1D: none defined
  # Constraint2D: none defined


  #                             _
  #  _   _ ___  ___ _ __    ___| | __ _ ___ ___
  # | | | / __|/ _ \ '__|  / __| |/ _` / __/ __|
  # | |_| \__ \  __/ |    | (__| | (_| \__ \__ \
  #  \__,_|___/\___|_|     \___|_|\__,_|___/___/
  # User defined classes initialization
  # User defined classes: S P L I N E W I N D S P E E D
  require_relative("../wind_data/spline_set_wind_data.rb",__FILE__)
  # User defined classes: M E S H
  data.Mesh =
  {
    :s0       => 0,
    :segments => [
      {
        :n      => 150,
        :length => 30,
      },
    ],
  };


end

# EOF
