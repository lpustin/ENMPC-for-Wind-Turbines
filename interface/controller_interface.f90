!**********************************************************************************************************************************
! LICENSING
! Copyright (C) 2015-2016  National Renewable Energy Laboratory
! Copyright (C) 2016-2017  Envision Energy USA, LTD
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!**********************************************************************************************************************************
SUBROUTINE DISCON ( avrSWAP, aviFAIL, accINFILE, avcOUTNAME, avcMSG ) BIND (C, NAME='DISCON')

   ! This Bladed-style DLL controller is used to implement a variable-speed
   ! generator-torque controller and PI collective blade pitch controller for
   ! the NREL Offshore 5MW baseline wind turbine.  This routine was written by
   ! J. Jonkman of NREL/NWTC for use in the IEA Annex XXIII OC3 studies.
   ! Modified for OC3Hywind configuration.

   ! Modified by B. Jonkman to conform to ISO C Bindings (standard Fortran 2003) and
   ! compile with either gfortran or Intel Visual Fortran (IVF)
   ! DO NOT REMOVE or MODIFY LINES starting with "!DEC$" or "!GCC$"
   ! !DEC$ specifies attributes for IVF and !GCC$ specifies attributes for gfortran.
   !
   ! Note that gfortran v5.x on Mac produces compiler errors with the DLLEXPORT attribute,
   ! so I've added the compiler directive IMPLICIT_DLLEXPORT.

use f90sockets, only : open_socket, writebuffer, readbuffer
use, intrinsic :: iso_c_binding

implicit none


integer, save :: counter=0

!LPUSTIN for socket
integer, save :: socket ! socket id
integer :: inet=0
integer :: port= 246810      ! port
character(len=1024)  :: host= "localhost"//achar(0)
character(len=1024) :: message_string
real(kind=8) :: ocp_outputs(2), ocp_inputs(3)


real(8), save  :: BldPitch0, GenTemp
real(8), PARAMETER :: Pi = 3.1415927

   ! Passed Variables:

REAL(C_FLOAT),          INTENT(INOUT) :: avrSWAP   (*)                  ! The swap array, used to pass data to, and receive data from, the DLL controller.
INTEGER(C_INT),         INTENT(INOUT) :: aviFAIL                        ! A flag used to indicate the success of this DLL call set as follows: 0 if the DLL call was successful, >0 if the DLL call was successful but cMessage should be issued as a warning messsage, <0 if the DLL call was unsuccessful or for any other reason the simulation is to be stopped at this point with cMessage as the error message.
CHARACTER(KIND=C_CHAR), INTENT(IN)    :: accINFILE (NINT(avrSWAP(50)))  ! The name of the parameter input file, 'DISCON.IN'.
CHARACTER(KIND=C_CHAR), INTENT(IN)    :: avcOUTNAME(NINT(avrSWAP(51)))  ! OUTNAME (Simulation RootName)
CHARACTER(KIND=C_CHAR), INTENT(INOUT) :: avcMSG    (NINT(avrSWAP(49)))  ! MESSAGE (Message from DLL to simulation code [ErrMsg])  The message which will be displayed by the calling program if aviFAIL <> 0.


   ! Local Variables:

REAL(8)                      :: Alpha                                           ! Current coefficient in the recursive, single-pole, low-pass filter, (-).
REAL(8)                      :: BlPitch   (3)                                   ! Current values of the blade pitch angles, rad.
REAL(8)                      :: ElapTime                                        ! Elapsed time since the last call to the controller, sec.
REAL(8), PARAMETER           :: CornerFreq    =       1.570796                  ! Corner frequency (-3dB point) in the recursive, single-pole, low-pass filter, rad/s. -- chosen to be 1/4 the blade edgewise natural frequency ( 1/4 of approx. 1Hz = 0.25Hz = 1.570796rad/s)
REAL(8)                      :: GenSpeed                                        ! Current  HSS (generator) speed, rad/s.
REAL(8), SAVE                :: GenSpeedF                                       ! Filtered HSS (generator) speed, rad/s.
REAL(8)                      :: GenTrq                                          ! Electrical generator torque, N-m.
REAL(8)                      :: GK                                              ! Current value of the gain correction factor, used in the gain scheduling law of the pitch controller, (-).
REAL(8)                      :: HorWindV                                        ! Horizontal hub-heigh wind speed, m/s.
REAL(8), SAVE                :: IntSpdErr                                       ! Current integral of speed error w.r.t. time, rad.
REAL(8), SAVE                :: LastGenTrq                                      ! Commanded electrical generator torque the last time the controller was called, N-m.
REAL(8), SAVE                :: LastTime                                        ! Last time this DLL was called, sec.
REAL(8), SAVE                :: LastTimePC                                      ! Last time the pitch  controller was called, sec.
REAL(8), SAVE                :: LastTimeVS                                      ! Last time the torque controller was called, sec.
REAL(8), PARAMETER           :: OnePlusEps    = 1.0 + EPSILON(OnePlusEps)       ! The number slighty greater than unity in single precision.
REAL(8), PARAMETER           :: PC_DT         =       0.00125                   ! Communication interval for pitch  controller, sec.
REAL(8), PARAMETER           :: PC_KI         =       0.0008965149   !JASON:REDUCE GAINS FOR HYWIND::0.008068634               ! Integral gain for pitch controller at rated pitch (zero), (-).
REAL(8), PARAMETER           :: PC_KK         =       0.1099965                 ! Pitch angle where the the derivative of the aerodynamic power w.r.t. pitch has increased by a factor of two relative to the derivative at rated pitch (zero), rad.
REAL(8), PARAMETER           :: PC_KP         =       0.006275604    !JASON:REDUCE GAINS FOR HYWIND:0.01882681                ! Proportional gain for pitch controller at rated pitch (zero), sec.
REAL(8), PARAMETER           :: PC_MaxPit     =       1.570796                  ! Maximum pitch setting in pitch controller, rad.
REAL(8), PARAMETER           :: PC_MaxRat     =       0.1396263                 ! Maximum pitch  rate (in absolute value) in pitch  controller, rad/s.
REAL(8), PARAMETER           :: PC_MinPit     =       0.0                       ! Minimum pitch setting in pitch controller, rad.
REAL(8), PARAMETER           :: PC_RefSpd     =     122.9096                    ! Desired (reference) HSS speed for pitch controller, rad/s.
REAL(8), SAVE                :: PitCom    (3)                                   ! Commanded pitch of each blade the last time the controller was called, rad.
REAL(8)                      :: PitComI                                         ! Integral term of command pitch, rad.
REAL(8)                      :: PitComP                                         ! Proportional term of command pitch, rad.
REAL(8)                      :: PitComT                                         ! Total command pitch based on the sum of the proportional and integral terms, rad.
REAL(8)                      :: PitRate   (3)                                   ! Pitch rates of each blade based on the current pitch angles and current pitch command, rad/s.
REAL(8), PARAMETER           :: R2D           =      57.295780                  ! Factor to convert radians to degrees.
REAL(8), PARAMETER           :: RPS2RPM       =       9.5492966                 ! Factor to convert radians per second to revolutions per minute.
REAL(8)                      :: SpdErr                                          ! Current speed error, rad/s.
REAL(8)                      :: Time                                            ! Current simulation time, sec.
REAL(8)                      :: TrqRate                                         ! Torque rate based on the current and last torque commands, N-m/s.
REAL(8), PARAMETER           :: VS_CtInSp     =      70.16224                   ! Transitional generator speed (HSS side) between regions 1 and 1 1/2, rad/s.
REAL(8), PARAMETER           :: VS_DT         =       0.00125                   ! Communication interval for torque controller, sec.
REAL(8), PARAMETER           :: VS_MaxRat     =   15000.0                       ! Maximum torque rate (in absolute value) in torque controller, N-m/s.
REAL(8), PARAMETER           :: VS_MaxTq      =   47402.91                      ! Maximum generator torque in Region 3 (HSS side), N-m. -- chosen to be 10% above VS_RtTq = 43.09355kNm
REAL(8), PARAMETER           :: VS_Rgn2K      =       2.332287                  ! Generator torque constant in Region 2 (HSS side), N-m/(rad/s)^2.
REAL(8), PARAMETER           :: VS_Rgn2Sp     =      91.21091                   ! Transitional generator speed (HSS side) between regions 1 1/2 and 2, rad/s.
REAL(8), PARAMETER           :: VS_Rgn3MP     =       0.01745329                ! Minimum pitch angle at which the torque is computed as if we are in region 3 regardless of the generator speed, rad. -- chosen to be 1.0 degree above PC_MinPit
REAL(8), PARAMETER           :: VS_RtGnSp     =     121.6805                    ! Rated generator speed (HSS side), rad/s. -- chosen to be 99% of PC_RefSpd
REAL(8), PARAMETER           :: VS_RtPwr      = 5296610.0                       ! Rated generator generator power in Region 3, Watts. -- chosen to be 5MW divided by the electrical generator efficiency of 94.4%
REAL(8), SAVE                :: VS_Slope15                                      ! Torque/speed slope of region 1 1/2 cut-in torque ramp , N-m/(rad/s).
REAL(8), SAVE                :: VS_Slope25                                      ! Torque/speed slope of region 2 1/2 induction generator, N-m/(rad/s).
REAL(8), PARAMETER           :: VS_SlPc       =      10.0                       ! Rated generator slip percentage in Region 2 1/2, %.
REAL(8), SAVE                :: VS_SySp                                         ! Synchronous speed of region 2 1/2 induction generator, rad/s.
REAL(8), SAVE                :: VS_TrGnSp                                       ! Transitional generator speed (HSS side) between regions 2 and 2 1/2, rad/s.

INTEGER(4)                   :: I                                               ! Generic index.
INTEGER(4)                   :: iStatus                                         ! A status flag set by the simulation as follows: 0 if this is the first call, 1 for all subsequent time steps, -1 if this is the final call at the end of the simulation.
INTEGER(4)                   :: K                                               ! Loops through blades.
INTEGER(4)                   :: NumBl                                           ! Number of blades, (-).
INTEGER(4), PARAMETER        :: UnDb          = 85                              ! I/O unit for the debugging information

INTEGER(4), PARAMETER        :: Un            = 87                              ! I/O unit for pack/unpack (checkpoint & restart)
INTEGER(4)                   :: ErrStat

LOGICAL(1), PARAMETER        :: PC_DbgOut     = .FALSE.                         ! Flag to indicate whether to output debugging information

CHARACTER(   1), PARAMETER   :: Tab           = CHAR( 9 )                       ! The tab character.
CHARACTER(  25), PARAMETER   :: FmtDat    = "(F8.3,99('"//Tab//"',ES10.3E2,:))" ! The format of the debugging data

CHARACTER(SIZE(accINFILE)-1) :: InFile                                          ! a Fortran version of the input C string (not considered an array here)    [subtract 1 for the C null-character]
CHARACTER(SIZE(avcOUTNAME)-1):: RootName                                        ! a Fortran version of the input C string (not considered an array here)    [subtract 1 for the C null-character]
CHARACTER(SIZE(avcMSG)-1)    :: ErrMsg                                          ! a Fortran version of the C string argument (not considered an array here) [subtract 1 for the C null-character]




   ! Load variables from calling program (See Appendix A of Bladed User's Guide):

iStatus      = NINT( avrSWAP( 1) )
NumBl        = NINT( avrSWAP(61) )

BlPitch  (1) =       avrSWAP( 4)
BlPitch  (2) =       avrSWAP(33)
BlPitch  (3) =       avrSWAP(34)
GenSpeed     =       avrSWAP(20)
HorWindV     =       avrSWAP(27)
Time         =       avrSWAP( 2)
GenTemp      =       0 !!!avrSWAP( 126)

   ! Convert C character arrays to Fortran strings:

RootName = TRANSFER( avcOUTNAME(1:LEN(RootName)), RootName )
I = INDEX(RootName,C_NULL_CHAR) - 1       ! if this has a c null character at the end...
IF ( I > 0 ) RootName = RootName(1:I)     ! remove it

InFile = TRANSFER( accINFILE(1:LEN(InFile)),  InFile )
I = INDEX(InFile,C_NULL_CHAR) - 1         ! if this has a c null character at the end...
IF ( I > 0 ) InFile = InFile(1:I)         ! remove it



   ! Initialize aviFAIL to 0:

aviFAIL      = 0


   ! Read any External Controller Parameters specified in the User Interface
   !   and initialize variables:
IF ( iStatus == 0 )  THEN  ! .TRUE. if we're on the first call to the DLL

   call open_socket(socket, inet, port, host)
   write(*,*) "OPENED CONNECTION WITH OCP"

   ! Inform users that we are using this user-defined routine:

   aviFAIL  = 1
   ErrMsg   = 'RUNNING WITH OCP CONTROLLER'
ENDIF



   ! Main control calculations:

IF ( ( iStatus >= 0 ) .AND. ( aviFAIL >= 0 ) )  THEN  ! Only compute control calculations if no error has occured and we are not on the last time step

  ! print *, "Time", Time

  !!!! OCP communication
  
  ocp_inputs(1)=Time ! time
  ocp_inputs(2)=GenSpeed/97. ! rotor speed
  ocp_inputs(3)=GenTemp ! Gen Temp


  write(message_string,'(1024(E18.11,2X))') ocp_inputs
  ! print *, message_string
  call writebuffer(socket, message_string,  len(message_string)) ! writing data


  !!!!! receive ocp_outputs at t (torque BldPitch0)
  call readbuffer(socket, message_string, len(message_string))
  ! print *, message_string
  read(message_string, *) (ocp_outputs(i),i=1,2)
  ! print *, "ocp_outputs(torque BldPitch0)"
  ! print *, ocp_outputs
  
  GenTrq=ocp_outputs(1)*1000   !kNm to Nm
  BldPitch0=ocp_outputs(2)*Pi/180. ! deg to rad



   ! Abort if the user has not requested a pitch angle actuator (See Appendix A
   !   of Bladed User's Guide):

   IF ( NINT(avrSWAP(10)) /= 0 )  THEN ! .TRUE. if a pitch angle actuator hasn't been requested
      aviFAIL = -1
      ErrMsg  = 'Pitch angle actuator not requested.'
   ENDIF


   ! Set unused outputs to zero (See Appendix A of Bladed User's Guide):

   avrSWAP(36) = 0.0 ! Shaft brake status: 0=off
   avrSWAP(41) = 0.0 ! Demanded yaw actuator torque
   avrSWAP(46) = 0.0 ! Demanded pitch rate (Collective pitch)
   avrSWAP(48) = 0.0 ! Demanded nacelle yaw rate
   avrSWAP(65) = 0.0 ! Number of variables returned for logging
   avrSWAP(72) = 0.0 ! Generator start-up resistance
   avrSWAP(79) = 0.0 ! Request for loads: 0=none
   avrSWAP(80) = 0.0 ! Variable slip current status
   avrSWAP(81) = 0.0 ! Variable slip current demand


   ! Set the generator contactor status, avrSWAP(35), to main (high speed)
   !   variable-speed generator, the torque override to yes, and command the
   !   generator torque (See Appendix A of Bladed User's Guide):

   avrSWAP(35) = 1.0          ! Generator contactor status: 1=main (high speed) variable-speed generator
   avrSWAP(56) = 0.0          ! Torque override: 0=yes
   avrSWAP(47) = GenTrq   ! Demanded generator torque


   ! Pitch control:

	!impose controller pitch
	avrSWAP(55) = 0.0       ! Pitch override: 0=yes
	avrSWAP(42) = BldPitch0 ! Use the command angles of all blades if using individual pitch
	avrSWAP(43) = BldPitch0 ! "
	avrSWAP(44) = BldPitch0 ! "


!=======================================================================



ELSEIF ( iStatus == -8 )  THEN
   ! pack
   OPEN( Un, FILE=TRIM( InFile ), STATUS='UNKNOWN', FORM='UNFORMATTED' , ACCESS='STREAM', IOSTAT=ErrStat, ACTION='WRITE' )

   IF ( ErrStat /= 0 ) THEN
      ErrMsg  = 'Cannot open file "'//TRIM( InFile )//'". Another program may have locked it for writing.'
      aviFAIL = -1
   ELSE

      ! write all static variables to the checkpoint file (inverse of unpack):
      WRITE( Un, IOSTAT=ErrStat ) GenSpeedF               ! Filtered HSS (generator) speed, rad/s.
      WRITE( Un, IOSTAT=ErrStat ) IntSpdErr               ! Current integral of speed error w.r.t. time, rad.
      WRITE( Un, IOSTAT=ErrStat ) LastGenTrq              ! Commanded electrical generator torque the last time the controller was called, N-m.
      WRITE( Un, IOSTAT=ErrStat ) LastTime                ! Last time this DLL was called, sec.
      WRITE( Un, IOSTAT=ErrStat ) LastTimePC              ! Last time the pitch  controller was called, sec.
      WRITE( Un, IOSTAT=ErrStat ) LastTimeVS              ! Last time the torque controller was called, sec.
      WRITE( Un, IOSTAT=ErrStat ) PitCom                  ! Commanded pitch of each blade the last time the controller was called, rad.
      WRITE( Un, IOSTAT=ErrStat ) VS_Slope15              ! Torque/speed slope of region 1 1/2 cut-in torque ramp , N-m/(rad/s).
      WRITE( Un, IOSTAT=ErrStat ) VS_Slope25              ! Torque/speed slope of region 2 1/2 induction generator, N-m/(rad/s).
      WRITE( Un, IOSTAT=ErrStat ) VS_SySp                 ! Synchronous speed of region 2 1/2 induction generator, rad/s.
      WRITE( Un, IOSTAT=ErrStat ) VS_TrGnSp               ! Transitional generator speed (HSS side) between regions 2 and 2 1/2, rad/s.

      CLOSE ( Un )

   END IF

ELSEIF( iStatus == -9 ) THEN
   !unpack
   OPEN( Un, FILE=TRIM( InFile ), STATUS='OLD', FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=ErrStat, ACTION='READ' )

   IF ( ErrStat /= 0 ) THEN
      aviFAIL = -1
      ErrMsg  = ' Cannot open file "'//TRIM( InFile )//'" for reading. Another program may have locked.'
   ELSE

      ! READ all static variables from the restart file (inverse of pack):
      READ( Un, IOSTAT=ErrStat ) GenSpeedF               ! Filtered HSS (generator) speed, rad/s.
      READ( Un, IOSTAT=ErrStat ) IntSpdErr               ! Current integral of speed error w.r.t. time, rad.
      READ( Un, IOSTAT=ErrStat ) LastGenTrq              ! Commanded electrical generator torque the last time the controller was called, N-m.
      READ( Un, IOSTAT=ErrStat ) LastTime                ! Last time this DLL was called, sec.
      READ( Un, IOSTAT=ErrStat ) LastTimePC              ! Last time the pitch  controller was called, sec.
      READ( Un, IOSTAT=ErrStat ) LastTimeVS              ! Last time the torque controller was called, sec.
      READ( Un, IOSTAT=ErrStat ) PitCom                  ! Commanded pitch of each blade the last time the controller was called, rad.
      READ( Un, IOSTAT=ErrStat ) VS_Slope15              ! Torque/speed slope of region 1 1/2 cut-in torque ramp , N-m/(rad/s).
      READ( Un, IOSTAT=ErrStat ) VS_Slope25              ! Torque/speed slope of region 2 1/2 induction generator, N-m/(rad/s).
      READ( Un, IOSTAT=ErrStat ) VS_SySp                 ! Synchronous speed of region 2 1/2 induction generator, rad/s.
      READ( Un, IOSTAT=ErrStat ) VS_TrGnSp               ! Transitional generator speed (HSS side) between regions 2 and 2 1/2, rad/s.

      CLOSE ( Un )
   END IF


ENDIF

avcMSG = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, avcMSG, SIZE(avcMSG) )

RETURN
END SUBROUTINE DISCON
!=======================================================================
