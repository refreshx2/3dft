

program ft3d
    use model_mod
    use scattering_factors
    use gfx
    use omp_lib
    implicit none
    double precision, parameter :: pi = 3.1415926536
    complex(kind=8), parameter :: cpi = (0.0,pi)
    complex(kind=8), parameter :: cpi2 = 2*cpi
    type(model) :: m
    character (len=256) :: model_filename
    integer :: istat
    double precision:: kminx, kmaxx, dkx
    double precision:: kminy, kmaxy, dky
    double precision:: kminz, kmaxz, dkz
    integer :: nkx, nky, nkz
    integer :: i,j,k,n ! Counters
    double precision, dimension(:,:,:), allocatable :: kgrid, ikgrid
    complex(kind=8), dimension(:,:,:), allocatable :: skgrid
    complex :: sk
    double precision :: dp, dpx, dpy, dpz
    double precision :: kvec
    integer :: allbinsize
    integer :: nthr
    double precision :: allstart
    logical :: writetootherside

    nthr = omp_get_max_threads()
    write(*,*) "OMP found a max number of threads of", nthr

    ! I still should rewrite how kmin and kmax's are defined
    ! based on how the fft code does it. I like that way.

    !call read_model("alsm_New8C0.xyz", m, istat)
    !call read_model("al_3x3x3.xyz", m, istat)
    !call read_model("al_chunk.xyz", m, istat)
    !call read_model("al_chunk_offcenter.xyz", m, istat)
    !call read_model("Zr50Cu35Al15_t3_final.xyz", m, istat)
    !call read_model("ZCA_t3_xtal.xyz", m, istat)
    !call read_model("xtal.t3.opposite.xyz", m, istat)
    !call read_model("icolike.t3.xyz", m, istat)
    !call read_model("mixed.xyz", m, istat)
    !call read_model("mixed_icolike.xyz", m, istat)
    !call read_model("Zr50Cu35Al15_t3_final_xtal_cut.xyz", m, istat)
    call read_model("sc_4.0.xyz", m, istat)
    call read_f_e

    allbinsize = 256
    allstart = -1.5

    kminx = allstart
    kmaxx = -allstart
    nkx = allbinsize
    dkx = (kmaxx-kminx)/float(nkx)

    kminy = allstart
    kmaxy = -allstart
    nky = allbinsize
    dky = (kmaxy-kminy)/float(nky)

    kminz = allstart
    kmaxz = -allstart
    nkz = allbinsize
    dkz = (kmaxz-kminz)/float(nkz)

    write(*,*) "Reciprocal space sampling in 1/Angstroms is:"
    write(*,*) "    kx: start:",kminx, "step:", dkx
    write(*,*) "    ky: start:",kminy, "step:", dky
    write(*,*) "    kz: start:",kminz, "step:", dkz


    allocate(skgrid(nkx,nky,nkz))
    allocate(ikgrid(nkx,nky,nkz))
    skgrid = (0.0,0.0)
    ikgrid = 0.0

    ! Equation:
    ! S(k) = Sum(over all atoms)[ f_i(k) * exp( 2*pi*i*k.r ) ]
    ! Where f_i is the atomic scattering factor for species i
    ! and k.r is the dot product of a k vector with every
    ! positition vector r for each atom in the model.
    ! You do this for every k vector in the grid.
    write(*,*) "Calculating FT..."
    !$omp parallel do private(i,j,k,n,dpx,dpy,dpz,kvec,dp,sk) shared(skgrid)
    do i=1, nkx
        dpx = (kminx+i*dkx)
        do j=1, nky
            dpy = (kminy+j*dky)
            !do k=1, nkz/2
            do k=1, nkz
                dpz = (kminz+k*dkz)
                kvec = sqrt(dpx**2+dpy**2+dpz**2)
                do n=1, m%natoms
                    dp = dpx*m%xx%ind(n) + dpy*m%yy%ind(n) + dpz*m%zz%ind(n)
                    !sk = f_e(m%znum%ind(n),kvec) * cdexp(cpi2*dp)
                    sk = cdexp(cpi2*dp)
                    skgrid(i,j,k) = skgrid(i,j,k) + sk
                    skgrid(nkx-i+1,nky-j+1,nkz-k+1) = skgrid(nkx-i+1,nky-j+1,nkz-k+1) + conjg(sk)
                    !skgrid(nkx-i+1,nky-j+1,nkz-k+1) = skgrid(nkx-i+1,nky-j+1,nkz-k+1) + conjg(sk)
                enddo
            enddo
        enddo
        write(*,*) i*(100.0/nkx), "percent done"
    enddo
    !$omp end parallel do


    ! Calculate I(k)
    write(*,*) "Calculating I(k)..."
    do i=1, nkx
        do j=1, nky
            do k=1, nkz
                ikgrid(i,j,k) = cdabs(skgrid(i,j,k))
            enddo
        enddo
    enddo

    write(*,*) "Writing output..."
    open(unit=52,file='out.gfx',form='formatted',status='unknown')
    !open(unit=52,file='Zr50Cu35Al15_t3_final_xtal_cut.gfx',form='formatted',status='unknown')
    !open(unit=52,file='Zr50_t3_256.gfx',form='formatted',status='unknown')
    !open(unit=52,file='Zr50_t3_64.gfx',form='formatted',status='unknown')
    !open(unit=52,file='al_3x3x3.gfx',form='formatted',status='unknown')
    !open(unit=52,file='al_chunk.gfx',form='formatted',status='unknown')
    !open(unit=52,file='al_chunk_offcenter.gfx',form='formatted',status='unknown')
    !open(unit=52,file='ZCA_t3_xtal.gfx',form='formatted',status='unknown')
    !open(unit=52,file='xtal.t3.opposite.gfx',form='formatted',status='unknown')
    !open(unit=52,file='icolike.t3.gfx',form='formatted',status='unknown')
    !open(unit=52,file='mixed.gfx',form='formatted',status='unknown')
    !open(unit=52,file='mixed_icolike.gfx',form='formatted',status='unknown')
    do k=1, nkz
        do i=1, nkx
            do j=1, nky
                write(52,"(1f12.6)",advance='no') ikgrid(i,j,k)
            enddo
        enddo
        write(*,*) k*(100.0/nkz), "percent done"
        write(52,*)
    enddo
    close(52)
    

end program ft3d